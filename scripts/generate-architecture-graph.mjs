import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, normalize, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const graphDir = join(root, 'graphs');
const repomixOutput = join(graphDir, 'repomix', 'production-code.json');
const architectureDir = join(graphDir, 'architecture');
const defaultRepomixHome = resolve(root, '..', 'repomix');
const repomixHome = process.env.REPOMIX_HOME
  ? resolve(process.env.REPOMIX_HOME)
  : defaultRepomixHome;
const repomixBin = join(repomixHome, 'bin', 'repomix.cjs');

function slash(value) {
  return value.split(sep).join('/');
}

function run(command, args, cwd = root) {
  return execFileSync(command, args, {
    cwd,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trim();
}

function generateCorpus() {
  if (!existsSync(repomixBin)) {
    throw new Error(
      `Repomix no esta construido en ${repomixBin}. Clone yamadashy/repomix fuera del proyecto y ejecute npm ci.`,
    );
  }
  mkdirSync(dirname(repomixOutput), { recursive: true });
  execFileSync(
    process.execPath,
    [repomixBin, '--config', join(graphDir, 'repomix.config.json'), '--quiet'],
    { cwd: root, stdio: 'inherit' },
  );
}

function classify(path) {
  if (/\.(spec|test)\.[^.]+$/.test(path) || path.includes('/test/')) return 'test';
  if (path.startsWith('.github/') || path.startsWith('infra/') || /(?:^|\/)(?:package|tsconfig|pubspec)[^/]*\.(?:json|yaml)$/.test(path)) return 'config';
  return 'production';
}

function subsystem(path) {
  if (path.startsWith('backend/')) return 'backend';
  if (path.startsWith('web_admin/')) return 'web_admin';
  if (path.startsWith('mobile_app/')) return 'mobile_app';
  if (path.startsWith('.github/') || path.startsWith('infra/')) return 'infrastructure';
  return 'root';
}

function resolveImport(from, specifier, fileSet) {
  if (specifier.startsWith('package:sas_gym/')) {
    const candidate = `mobile_app/lib/${specifier.slice('package:sas_gym/'.length)}`;
    return fileSet.has(candidate) ? candidate : null;
  }
  if (!specifier.startsWith('.')) return null;
  const base = slash(normalize(join(dirname(from), specifier)));
  const candidates = extname(base)
    ? [base]
    : [base, `${base}.ts`, `${base}.tsx`, `${base}.js`, `${base}.jsx`, `${base}.dart`, `${base}/index.ts`, `${base}/index.js`, `${base}/index.jsx`];
  return candidates.find((candidate) => fileSet.has(candidate)) ?? null;
}

function addEdge(edges, seen, source, target, relation, metadata = {}) {
  if (!source || !target || source === target) return;
  const key = `${source}|${target}|${relation}`;
  if (seen.has(key)) return;
  seen.add(key);
  edges.push({ source, target, relation, ...metadata });
}

function endpointId(method, path) {
  return `endpoint:${method.toUpperCase()}:${path.replace(/\/+$/, '') || '/'}`;
}

function joinRoute(base, route) {
  const value = `/${[base, route].filter(Boolean).join('/')}`.replace(/\/{2,}/g, '/');
  return value.length > 1 ? value.replace(/\/$/, '') : value;
}

function routesMatch(expected, consumed) {
  const expectedParts = expected.split('/').filter(Boolean);
  const consumedParts = consumed.split('/').filter(Boolean);
  if (expectedParts.length !== consumedParts.length) return false;
  return expectedParts.every((part, index) =>
    part.startsWith(':') || consumedParts[index].startsWith('$') || part === consumedParts[index],
  );
}

function extractBackendEndpoints(path, content, endpointNodes) {
  const controller = content.match(/@Controller\(\s*['"`]([^'"`]*)['"`]\s*\)/);
  if (!controller) return;
  const decorator = /@(Get|Post|Put|Patch|Delete)\(\s*(?:['"`]([^'"`]*)['"`])?\s*\)/g;
  for (const match of content.matchAll(decorator)) {
    const method = match[1].toUpperCase();
    const route = joinRoute(controller[1], match[2] ?? '');
    endpointNodes.set(endpointId(method, route), {
      id: endpointId(method, route),
      label: `${method} ${route}`,
      kind: 'endpoint',
      classification: 'production',
      subsystem: 'backend',
      sourceFile: path,
      method,
      route,
    });
  }
}

function extractApiCalls(path, content) {
  const calls = [];
  const patterns = [
    { regex: /apiRequest\(\s*([`'"])([^`'"]+)\1\s*,?\s*([^)]*)\)/g, defaultMethod: 'GET' },
    { regex: /\.dio\.(get|post|put|patch|delete)\(\s*([`'"])([^`'"]+)\2/g, dio: true },
  ];
  for (const pattern of patterns) {
    for (const match of content.matchAll(pattern.regex)) {
      const rawPath = pattern.dio ? match[3] : match[2];
      if (rawPath.includes('${')) continue;
      const method = pattern.dio
        ? match[1].toUpperCase()
        : (match[3]?.match(/method\s*:\s*['"](GET|POST|PUT|PATCH|DELETE)['"]/i)?.[1] ?? pattern.defaultMethod).toUpperCase();
      calls.push({ method, route: rawPath.startsWith('/') ? rawPath : `/${rawPath}`, sourceFile: path });
    }
  }
  return calls;
}

function stronglyConnected(nodes, edges) {
  const adjacency = new Map(nodes.map((node) => [node.id, []]));
  for (const edge of edges.filter((item) => item.relation === 'imports')) {
    adjacency.get(edge.source)?.push(edge.target);
  }
  let index = 0;
  const stack = [];
  const indices = new Map();
  const low = new Map();
  const onStack = new Set();
  const components = [];

  function visit(id) {
    indices.set(id, index);
    low.set(id, index);
    index += 1;
    stack.push(id);
    onStack.add(id);
    for (const next of adjacency.get(id) ?? []) {
      if (!indices.has(next)) {
        visit(next);
        low.set(id, Math.min(low.get(id), low.get(next)));
      } else if (onStack.has(next)) {
        low.set(id, Math.min(low.get(id), indices.get(next)));
      }
    }
    if (low.get(id) === indices.get(id)) {
      const component = [];
      let current;
      do {
        current = stack.pop();
        onStack.delete(current);
        component.push(current);
      } while (current !== id);
      if (component.length > 1) components.push(component.sort());
    }
  }
  for (const node of nodes) if (!indices.has(node.id)) visit(node.id);
  return components;
}

function buildGraph(corpus) {
  const files = corpus.files ?? {};
  const fileSet = new Set(Object.keys(files).map(slash));
  const nodes = [...fileSet].sort().map((path) => ({
    id: path,
    label: path.split('/').at(-1),
    kind: 'file',
    classification: classify(path),
    subsystem: subsystem(path),
    sourceFile: path,
    lines: files[path].split(/\r?\n/).length,
  }));
  const endpointNodes = new Map();
  const edges = [];
  const seen = new Set();
  const calls = [];

  for (const [rawPath, content] of Object.entries(files)) {
    const path = slash(rawPath);
    const imports = new Set();
    const jsImport = /(?:import|export)\s+(?:[^'"`]*?\s+from\s+)?['"`]([^'"`]+)['"`]/g;
    const dartImport = /(?:import|export)\s+['"]([^'"]+)['"]/g;
    for (const regex of [jsImport, dartImport]) {
      for (const match of content.matchAll(regex)) imports.add(match[1]);
    }
    for (const specifier of imports) {
      const target = resolveImport(path, specifier, fileSet);
      addEdge(edges, seen, path, target, 'imports', { specifier });
    }
    if (path.startsWith('backend/src/')) extractBackendEndpoints(path, content, endpointNodes);
    if (path.startsWith('web_admin/') || path.startsWith('mobile_app/lib/')) calls.push(...extractApiCalls(path, content));
    if (path.startsWith('mobile_app/lib/') && path !== 'mobile_app/lib/data/gym_state.dart' && /\b(?:GymState|GymStateProvider)\b/.test(content)) {
      addEdge(edges, seen, path, 'mobile_app/lib/data/gym_state.dart', 'state_dependency');
    }
  }

  nodes.push(...endpointNodes.values());
  for (const endpoint of endpointNodes.values()) addEdge(edges, seen, endpoint.sourceFile, endpoint.id, 'defines_endpoint');
  for (const call of calls) {
    const exact = endpointId(call.method, call.route);
    const target = endpointNodes.has(exact)
      ? exact
      : [...endpointNodes.values()].find(
          (endpoint) =>
            endpoint.method === call.method &&
            routesMatch(endpoint.route, call.route),
        )?.id;
    addEdge(edges, seen, call.sourceFile, target ?? exact, target ? 'api_call' : 'unmatched_api_call', { method: call.method, route: call.route });
    if (!target && !nodes.some((node) => node.id === exact)) {
      nodes.push({ id: exact, label: `${call.method} ${call.route}`, kind: 'unmatched_endpoint', classification: 'production', subsystem: 'contract', sourceFile: call.sourceFile });
    }
  }

  const degree = new Map(nodes.map((node) => [node.id, 0]));
  for (const edge of edges) {
    degree.set(edge.source, (degree.get(edge.source) ?? 0) + 1);
    degree.set(edge.target, (degree.get(edge.target) ?? 0) + 1);
  }
  for (const node of nodes) node.degree = degree.get(node.id) ?? 0;
  const cycles = stronglyConnected(nodes, edges);
  return { nodes, edges, cycles };
}

function report(graph, metadata) {
  const productive = graph.nodes.filter((node) => node.classification === 'production' && node.kind === 'file');
  const hubs = [...productive].sort((a, b) => b.degree - a.degree).slice(0, 20);
  const unmatched = graph.edges.filter((edge) => edge.relation === 'unmatched_api_call');
  const bySubsystem = Object.entries(Object.groupBy(productive, (node) => node.subsystem)).map(([name, list]) => `| ${name} | ${list.length} |`);
  return `# Architecture Graph Report

Generated from \`${metadata.commit}\` using Repomix ${metadata.repomixVersion} (\`${metadata.repomixCommit.slice(0, 12)}\`).

## Scope

- ${productive.length} production files
- ${graph.nodes.length} total nodes
- ${graph.edges.length} directed edges
- ${graph.cycles.length} import cycles
- ${unmatched.length} API calls without an exact backend endpoint match
- Working tree at generation: ${metadata.dirty ? 'dirty' : 'clean'}

| Subsystem | Production files |
| --- | ---: |
${bySubsystem.join('\n')}

## Highest-impact production files

| Degree | File |
| ---: | --- |
${hubs.map((node) => `| ${node.degree} | \`${node.sourceFile}\` |`).join('\n')}

## Import cycles

${graph.cycles.length ? graph.cycles.map((cycle) => `- ${cycle.map((item) => `\`${item}\``).join(' -> ')}`).join('\n') : 'No production import cycles detected.'}

## Contract gaps

${unmatched.length ? unmatched.map((edge) => `- \`${edge.method} ${edge.route}\` consumed by \`${edge.source}\``).join('\n') : 'All statically detectable API calls match a backend endpoint.'}

## Interpretation

This report separates product code from tests and infrastructure. Dynamic routes and calls assembled across variables require contract tests and may appear as unmatched.
`;
}

function html(graph, metadata) {
  const payload = JSON.stringify({ nodes: graph.nodes, edges: graph.edges });
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SAS Gym architecture graph</title><style>
body{font:14px ui-monospace,SFMono-Regular,Consolas,monospace;margin:0;background:#f4f1e8;color:#17221c}header{padding:20px;background:#173f35;color:#fff}main{padding:18px}.controls{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:14px}input,select{padding:9px;border:1px solid #8d9b91;background:#fff}.grid{display:grid;grid-template-columns:minmax(320px,1fr) minmax(360px,2fr);gap:16px}.panel{background:#fff;border:1px solid #c9c4b7;padding:12px;overflow:auto;max-height:75vh}table{border-collapse:collapse;width:100%}td,th{padding:7px;border-bottom:1px solid #e5e1d7;text-align:left}button{all:unset;cursor:pointer;color:#075f4b}code{font-size:12px}@media(max-width:800px){.grid{grid-template-columns:1fr}}
</style></head><body><header><h1>SAS Gym architecture graph</h1><div>${metadata.commit.slice(0, 12)} · ${graph.nodes.length} nodes · ${graph.edges.length} edges</div></header><main>
<div class="controls"><input id="query" placeholder="Filter files"><select id="subsystem"><option value="">All subsystems</option><option>backend</option><option>web_admin</option><option>mobile_app</option><option>infrastructure</option><option>contract</option></select></div>
<div class="grid"><section class="panel"><table><thead><tr><th>Degree</th><th>Node</th></tr></thead><tbody id="nodes"></tbody></table></section><section class="panel"><h2 id="title">Select a node</h2><div id="details"></div></section></div>
<script>const graph=${payload};const byId=new Map(graph.nodes.map(n=>[n.id,n]));const q=document.querySelector('#query'),s=document.querySelector('#subsystem'),body=document.querySelector('#nodes');function show(id){const n=byId.get(id),edges=graph.edges.filter(e=>e.source===id||e.target===id);document.querySelector('#title').textContent=n.label;document.querySelector('#details').innerHTML='<p><code>'+n.id+'</code></p><p>'+n.subsystem+' · '+n.classification+' · degree '+n.degree+'</p><table><tr><th>Relation</th><th>Connected node</th></tr>'+edges.map(e=>'<tr><td>'+e.relation+'</td><td><code>'+(e.source===id?e.target:e.source)+'</code></td></tr>').join('')+'</table>'}function render(){const term=q.value.toLowerCase(),sub=s.value;body.innerHTML=graph.nodes.filter(n=>(!sub||n.subsystem===sub)&&n.id.toLowerCase().includes(term)).sort((a,b)=>b.degree-a.degree).slice(0,500).map(n=>'<tr><td>'+n.degree+'</td><td><button data-id="'+n.id.replaceAll('"','&quot;')+'">'+n.id+'</button></td></tr>').join('');body.querySelectorAll('button').forEach(b=>b.onclick=()=>show(b.dataset.id))}q.oninput=render;s.onchange=render;render();</script></main></body></html>`;
}

generateCorpus();
const corpusText = readFileSync(repomixOutput, 'utf8');
const corpus = JSON.parse(corpusText);
const metadata = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  commit: run('git', ['rev-parse', 'HEAD']),
  dirty: Boolean(run('git', ['status', '--porcelain'])),
  repomixVersion: JSON.parse(readFileSync(join(repomixHome, 'package.json'), 'utf8')).version,
  repomixCommit: run('git', ['rev-parse', 'HEAD'], repomixHome),
  corpusSha256: createHash('sha256').update(corpusText).digest('hex'),
};
const graph = buildGraph(corpus);
mkdirSync(architectureDir, { recursive: true });
writeFileSync(join(architectureDir, 'graph.json'), `${JSON.stringify({ metadata, ...graph }, null, 2)}\n`);
writeFileSync(join(architectureDir, 'baseline.json'), `${JSON.stringify({ metadata, counts: { nodes: graph.nodes.length, edges: graph.edges.length, cycles: graph.cycles.length } }, null, 2)}\n`);
writeFileSync(join(architectureDir, 'REPORT.md'), report(graph, metadata));
writeFileSync(join(architectureDir, 'graph.html'), html(graph, metadata));
console.log(`Architecture graph: ${graph.nodes.length} nodes, ${graph.edges.length} edges, ${graph.cycles.length} cycles.`);
