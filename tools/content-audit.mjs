import fs from 'node:fs';
const recipes=JSON.parse(fs.readFileSync('assets/content/recipes_v1_1.json','utf8'));
const cards=JSON.parse(fs.readFileSync('assets/content/knowledge_v1_1.json','utf8'));
if(recipes.length!==100||cards.length!==300)throw Error('Wrong content counts');
for(const list of [recipes,cards])if(new Set(list.map(x=>x.id)).size!==list.length)throw Error('Duplicate IDs');
const sources=new Map();
for(const k of cards){
  const row=sources.get(k.sourceUrl)??{name:k.sourceName,cards:[]};
  row.cards.push(k);sources.set(k.sourceUrl,row);
}
let md='# V1.1.0 内容来源与核查索引\n\n核查日期：2026-10-03。新增100道菜谱、300条知识；保留6道原菜谱与18条原知识。\n\n';
md+='菜品从美食天下热门分类、下厨房高参与度家常菜菜单及豆果热门分类中选取常见家庭菜式，不表示实时全网热度排名。配比和步骤为独立编写的两人份家庭适配，烹调时间是检查参考，不是安全保证。菜谱安全提示引用知识库中的机构依据。插画为项目原创的成品示意，不是实拍。\n\n';
md+='知识是依据机构资料独立整理的中文摘要，不把实践配比写成机构标准。USDA日期标签条目明确限于美国语境；按产品本地标签使用。最低中心温度采用机构摄氏建议，安全与口感分别判断。\n\n';
md+='## 新菜谱选品索引\n\n|菜名|ID|选品参考|插画形态|\n|---|---|---|---|\n';
for(const r of recipes)md+=`|${r.name}|${r.id}|[参考页面](${r.sourceUrl})|${r.dishStyle}|\n`;
md+='\n## 新知识：机构、原文和逐条索引\n\n';
for(const [url,row] of sources){
  md+=`### ${row.name}\n\n[原始资料](${url}) · ${row.cards.length} 条\n\n`;
  for(const k of row.cards)md+=`- ${k.id}：${k.title}\n`;
  md+='\n';
}
fs.writeFileSync('docs/V1.1.0内容来源.md',md.trimEnd()+'\n');
console.log(JSON.stringify({recipes:recipes.length,knowledge:cards.length,authoritativePages:sources.size}));
