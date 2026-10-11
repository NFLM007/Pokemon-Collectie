import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const html=readFileSync('index.html','utf8');
const scripts=[...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)]
  .filter(m=>!/(?:^|\s)src\s*=/.test(m[1]) && m[2].trim());
assert(scripts.length>0,'No inline application scripts found');
for(const [index,match] of scripts.entries()){
  const attrs=match[1],code=match[2];
  if(/type\s*=\s*["']module["']/.test(attrs)){
    if(typeof vm.SourceTextModule==='function')new vm.SourceTextModule(code);
    else console.log('Skipping module syntax check: SourceTextModule unavailable');
  }else new vm.Script(code,{filename:'index.html:inline-script-'+(index+1)});
}
for(const name of ['renderHome','renderBinder','availableVariants','loadMeta','init']){
  assert(html.includes('function '+name+'('),'Missing core function: '+name);
}
assert(!html.includes('if(!base&&["IR","UR","SIR","MHR/HR"].includes(v))base=a.filter(x=>x==="Holo").length'),
  'Known bug: seed Holo ownership is duplicated into rare variants');
console.log('Static app checks passed ('+scripts.length+' inline scripts).');
