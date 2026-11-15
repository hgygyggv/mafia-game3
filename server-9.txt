'use strict';
/* سرور آنلاین مافیا — بدون نیاز به نصب پکیج (Node 16+)   اجرا: node server.js
   فایل HTML بازی را کنار همین فایل بگذار؛ سرور خودش بازی را هم نمایش می‌دهد (یک لینک برای همه).
   ENV: PORT · ADMIN_PASS (پیش‌فرض Sc..1212) · MIN_PLAYERS (پیش‌فرض 4) · TURN_URL/TURN_USER/TURN_PASS · DATA_FILE */
const http=require('http'),crypto=require('crypto'),fs=require('fs'),path=require('path'),zlib=require('zlib');
let RQ=[];
const rkNotify=()=>{RQ=RQ.filter(n=>conns[n]&&!where[n]);RQ.forEach(n=>to(n,{t:'rkstate',n:RQ.length,max:10}));if(RQ.length>=10){const ps=RQ.splice(0,10);const r=mkRoom('امتیازی','بازپرس',ps[0],true);ps.forEach(n=>{r.m.push({n,rd:1});where[n]=r.id});ps.forEach(n=>to(n,{t:'rkfound',id:r.id}));pushRoom(r);start(r);pushLobbies();RQ.forEach(n=>to(n,{t:'rkstate',n:RQ.length,max:10}))}};
const E=process.env,PORT=E.PORT||8080,ADMIN=E.ADMIN_PASS||'Sc..1212',MINP=+E.MIN_PLAYERS||4,TS=+E.TIME_SCALE||1,FILE=E.DATA_FILE||path.join(__dirname,'data.json');
let DB={users:{},bans:{},lg:{}};try{DB=Object.assign(DB,JSON.parse(fs.readFileSync(FILE,'utf8')))}catch(e){}DB.vip=DB.vip||{};DB.vipIp=DB.vipIp||{};DB.sups=DB.sups||[];DB.lregs=DB.lregs||{};DB.lbBan=DB.lbBan||{};DB.scs=DB.scs||{};DB.cimg=DB.cimg||{};DB.reps=DB.reps||[];['users','bans','vip','vipIp','lg','lregs','scs','lbBan'].forEach(k=>{if(DB[k]&&typeof DB[k]==='object'&&!Array.isArray(DB[k]))Object.setPrototypeOf(DB[k],null)});
let dirty=0;const save=()=>{dirty=1};setInterval(()=>{if(dirty){dirty=0;try{fs.writeFileSync(FILE,JSON.stringify(DB))}catch(e){}}},5000);
const ICE=[{urls:'stun:stun.l.google.com:19302'},{urls:'stun:stun1.l.google.com:19302'}];
if(E.TURN_URL)ICE.push({urls:E.TURN_URL.split(','),username:E.TURN_USER,credential:E.TURN_PASS});
const rep=(a,n)=>Array(n).fill(a),M='مافیا ساده',C='شهروند ساده',isM=p=>/مافیا/.test(p.r);
const SC={'تکاور':['رئیس مافیا',M,M,'دکتر','کارآگاه','تکاور','نگهبان',...rep(C,3)],'بازپرس':['رئیس مافیا',M,M,'دکتر','بازپرس','تفنگدار',...rep(C,4)],'اختصاصی':['رئیس مافیا',M,'کارآگاه','تفنگدار',...rep(C,3)]};
const RT={'رئیس مافیا':'m','مافیا ساده':'m','هکر مافیا':'m','فریبکار مافیا':'m','تروریست مافیا':'m','شهروند ساده':'c','دکتر':'c','کارآگاه':'c','بازپرس':'c','تکاور':'c','نگهبان':'c','تفنگدار':'c','شهردار':'c','بادیگارد':'c','شکارچی':'c','زندانبان':'c','قاتل زنجیره‌ای':'i','دلقک':'i','بازمانده':'i','آتش‌افروز':'i'};
const SIMPLE={'مافیا ساده':1,'شهروند ساده':1},KILLER={'قاتل زنجیره‌ای':1,'آتش‌افروز':1};
const NIGHTR={'دکتر':1,'کارآگاه':1,'بازپرس':1,'تکاور':1,'تفنگدار':1,'بادیگارد':1,'هکر مافیا':1,'فریبکار مافیا':1,'زندانبان':1,'قاتل زنجیره‌ای':1,'آتش‌افروز':1};
const scList=u=>({t:'scmine',list:Object.values(DB.scs).filter(x=>x.owner===u).map(x=>({id:x.id,name:x.name,roles:x.roles}))});
const PRICES={"a1":300,"a2":300,"a3":300,"a4":300,"a5":300,"a6":300,"a7":300,"a8":300,"a9":300,"a10":300,"a11":300,"a12":300,"a13":300,"a14":300,"a15":300,"a16":300,"a17":300,"a18":300,"a19":300,"a20":300,"a21":300,"a22":300,"a23":300,"a24":300,"a25":300,"a26":300,"a27":300,"a28":300,"a29":300,"a30":300,"a32":300,"a33":300,"a36":300,"a37":300,"a38":300,"a39":300,"a40":300,"a41":300,"a42":300,"a43":300,"a44":300,"a45":300,"a46":300,"a47":300,"a48":300,"a49":300,"a50":300,"a51":300,"a901":250,"a902":300,"a903":300,"a904":300,"a905":300,"a906":300,"a907":300,"a908":300,"a909":300,"a910":300,"a911":300,"a912":300,"a913":300,"a914":300,"a915":300,"a916":300,"a917":300,"a918":300,"a919":300,"a920":300,"a921":300,"a922":300,"a923":300,"a924":300,"a925":300,"a926":300,"a927":300,"a928":300,"a929":300,"a930":300,"a931":300,"a932":300,"a933":300,"a934":300,"a935":300,"a950":250,"a951":300,"a952":300,"a953":250,"a954":300,"a955":300,"a956":300,"a957":300,"a958":300,"a959":300,"fr":1400,"fy":1000,"fw":2000,"fb":1500,"f5":1200,"f6":1600,"f7":1300,"f8":1700,"f9":1800,"f10":1800,"f11":2000,"fx1":1500,"fx2":1500,"fx3":1500,"fx4":1500,"fx5":1500,"c0":1200,"c1":1400,"c2":2000,"c5":2200,"c6":2000,"c7":2400,"c8":2400,"c9":2200,"c10":2000,"c11":2600,"a2001":300,"a2002":300,"a2003":300,"a2004":300,"a2005":300,"a2006":300,"a2007":300,"a2008":300,"a2009":300,"a2010":300,"a2011":300,"a2012":300,"a2013":300,"a2014":300,"a2015":300,"a2016":300,"a2017":300,"a2018":300,"a2019":300,"a2020":300,"a2021":300,"a2022":300,"a2023":300,"a2024":300,"a2025":300,"a2026":300,"a2027":300,"fk1":1200,"ct1":1500},FREEI={a0:1};
const okEq=(u,e)=>{const f=(v,def)=>{v=String(v||def).slice(0,30);return v===def||u.owned.includes(v)?v:def};return{a:f(e.a,'a0'),f:f(e.f,''),c:f(e.c,'')}};
[PRICES,FREEI,RT,SIMPLE,KILLER,NIGHTR,SC].forEach(o=>Object.setPrototypeOf(o,null));const ADMTRY=Object.create(null);
const MAXR=Object.assign(Object.create(null),{'رئیس مافیا':1,'شهردار':1});
function scCheck(rl){if(rl.length<4)return 'حداقل ۴ نقش لازم است';if(rl.length>16)return 'حداکثر ۱۶ نقش مجاز است';const cnt={};for(const r of rl){if(!RT[r])return 'نقش نامعتبر: '+r;cnt[r]=(cnt[r]||0)+1;if(!SIMPLE[r]&&cnt[r]>(MAXR[r]||4))return 'نقش «'+r+'» بیشتر از '+(MAXR[r]||4)+' عدد مجاز نیست'}const mf=rl.filter(r=>RT[r]==='m').length,cf=rl.filter(r=>RT[r]==='c').length;if(mf<1)return 'حداقل یک مافیا لازم است';if(cf<1)return 'حداقل یک شهروند لازم است';if(mf*2>=rl.length)return 'تعداد مافیا باید کمتر از نصف بازیکنان باشد';return ''}
function fitRoles(rl,n){rl=rl.slice();if(n>=rl.length)return rl;const M0=rl.filter(r=>RT[r]==='m'),C0=rl.filter(r=>RT[r]==='c'),I0=rl.filter(r=>RT[r]==='i');
 let mf=Math.min(M0.length,Math.max(1,Math.round(M0.length*n/rl.length)),Math.max(1,Math.floor((n-1)/2))),ic=Math.min(I0.length,Math.round(I0.length*n/rl.length)),cf=n-mf-ic;
 if(cf<1){if(ic>0){ic--;cf++}else if(mf>1){mf--;cf++}}cf=Math.min(cf,C0.length);
 const mx=Math.max(1,Math.floor((n-1)/2));while(mf+ic+cf<n){if(cf<C0.length)cf++;else if(ic<I0.length)ic++;else if(mf<Math.min(M0.length,mx))mf++;else break}
 while(mf+ic+cf>n){if(ic>0)ic--;else if(cf>1)cf--;else mf--}
 const pick=(arr,k,keep)=>{if(k>=arr.length)return arr.slice();const out=keep.filter(x=>arr.includes(x)).slice(0,k);const sp=shuf(arr.filter(x=>!SIMPLE[x]&&!out.includes(x)));for(const x of sp)if(out.length<k)out.push(x);const sm=arr.filter(x=>SIMPLE[x]);for(const x of sm)if(out.length<k)out.push(x);return out};
 return shuf([...pick(M0,mf,['رئیس مافیا']),...pick(C0,cf,[]),...pick(I0,ic,[])])}

/* ---- v68: ۴ آواتار ویژه‌ی روز؛ هر ۲۴ ساعت (نیمه‌شب تهران) از بین همه‌ی آواتارهای فروشگاه عوض می‌شوند ---- */
const AVIDS=Object.keys(PRICES).filter(k=>/^a\d+$/.test(k)).sort((a,b)=>(+a.slice(1))-(+b.slice(1)));
['a950','a953','a901'].forEach(i=>{if(PRICES[i]===250)PRICES[i]=300});
const DEAL_PRICE=+process.env.DEAL_PRICE||200,DEAL_N=4,TZOFF=12600000,DAYMS=864e5;
function mul32(a){return function(){a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
function dealsFor(day){const cyc=Math.max(1,Math.ceil(AVIDS.length/DEAL_N)),cy=Math.floor(day/cyc),pos=((day%cyc)+cyc)%cyc,rg=mul32(cy*7919+13),arr=AVIDS.slice();for(let i=arr.length-1;i>0;i--){const j=Math.floor(rg()*(i+1));[arr[i],arr[j]]=[arr[j],arr[i]]}const w=arr.concat(arr);return w.slice(pos*DEAL_N,pos*DEAL_N+DEAL_N)}
const dayNow=()=>Math.floor((Date.now()+TZOFF)/DAYMS);
function dealsInfo(){const day=dayNow();return{day,ids:dealsFor(day),price:DEAL_PRICE,old:300,next:(day+1)*DAYMS-TZOFF-Date.now()}}
function dealPrice(x){const day=dayNow(),grace=((Date.now()+TZOFF)%DAYMS)<9e5;if(dealsFor(day).includes(x)||(grace&&dealsFor(day-1).includes(x)))return Math.min(DEAL_PRICE,PRICES[x]||DEAL_PRICE);return PRICES[x]}
const ownImgs=u=>{const o={};(u.owned||[]).forEach(x=>{if(DB.cimg&&DB.cimg[x])o[x]=DB.cimg[x]});return o};
function rankOf(u){const pts=DB.lg[u]||0;if(pts<=0)return 0;let n=1;for(const k in DB.lg){if(DB.lg[k]>pts)n++}return n}
const conns=Object.create(null),where=Object.create(null),R=Object.create(null),Q=[];let RID=1;
const sleep=ms=>new Promise(f=>setTimeout(f,ms/TS)),rnd=a=>a[Math.floor(Math.random()*a.length)];
const shuf=a=>{for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
const clean=s=>String(s||'').replace(/[<>&"'`\\\x00-\x1f]/g,'').trim().slice(0,24);

/* ---------- WebSocket (RFC 6455) ---------- */
function frame(b,op){b=Buffer.isBuffer(b)?b:Buffer.from(b);const n=b.length;let h;if(n<126)h=Buffer.from([128|op,n]);else if(n<65536){h=Buffer.alloc(4);h[0]=128|op;h[1]=126;h.writeUInt16BE(n,2)}else{h=Buffer.alloc(10);h[0]=128|op;h[1]=127;h.writeBigUInt64BE(BigInt(n),2)}return Buffer.concat([h,b])}
let PAGE=null,GZ=null;try{const all=fs.readdirSync(__dirname),f=all.find(x=>x.toLowerCase()==='index.html')||all.find(x=>/\.html?$/i.test(x));if(f){PAGE=Buffer.from(fs.readFileSync(path.join(__dirname,f),'utf8').replace('</head>','<script>window.MAFIA_SRV=1</script></head>'));GZ=zlib.gzipSync(PAGE)}}catch(e){}
const server=http.createServer((q,s)=>{if(PAGE&&/^\/(\?.*)?$/.test(q.url)){const gz=/gzip/.test(q.headers['accept-encoding']||'');const h={'content-type':'text/html;charset=utf-8'};if(gz)h['content-encoding']='gzip';s.writeHead(200,h);return s.end(gz?GZ:PAGE)}s.writeHead(200,{'content-type':'text/plain;charset=utf-8'});s.end('Mafia server OK')});
server.on('upgrade',(req,sock)=>{const k=req.headers['sec-websocket-key'];if(!k)return sock.destroy();const ip=String(req.headers['x-forwarded-for']||sock.remoteAddress||'').split(',')[0].trim();
 sock.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: '+crypto.createHash('sha1').update(k+'258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64')+'\r\n\r\n');sock.setNoDelay(true);
 const c={ip,sock,buf:Buffer.alloc(0),fr:'',name:null,send:o=>{try{if(!sock.destroyed)sock.write(frame(JSON.stringify(o),1))}catch(e){}},fatal(e){c.send({t:'err',e,fatal:1});setTimeout(()=>sock.end(),150)}};
 sock.on('data',d=>{c.buf=Buffer.concat([c.buf,d]);for(;;){const b=c.buf;if(b.length<2)return;let n=b[1]&127,o=2;if(n===126){if(b.length<4)return;n=b.readUInt16BE(2);o=4}else if(n===127){if(b.length<10)return;n=Number(b.readBigUInt64BE(2));o=10}
  if(n>6e6)return sock.destroy();const mk=(b[1]&128)?4:0;if(b.length<o+mk+n)return;const p=Buffer.from(b.slice(o+mk,o+mk+n));if(mk)for(let i=0;i<n;i++)p[i]^=b[o+(i&3)];
  const fin=b[0]&128,op=b[0]&15;c.buf=b.slice(o+mk+n);
  if(op===8)return sock.end();if(op===9){sock.write(frame(p,10));continue}if(op===10)continue;
  c.fr+=p.toString();if(c.fr.length>1e6){c.fr='';return sock.destroy()}if(fin){const t=c.fr;c.fr='';msg(c,t)}}});
 sock.on('close',()=>drop(c));sock.on('error',()=>{})});
setInterval(()=>{for(const n in conns)try{conns[n].sock.write(frame('',9))}catch(e){}},25000);
process.on('uncaughtException',e=>console.error(e));

/* ---------- لابی‌ها ---------- */
const to=(n,o)=>conns[n]&&conns[n].send(o),bc=(r,o)=>{r.m.forEach(x=>where[x.n]===r.id&&to(x.n,o));(r.w||[]).forEach(n=>to(n,o))};
const tkNow=l=>l.hrs;const tkOf=r=>{const l=r.lid&&DB.lregs[r.lid];if(!l||l.st!=='ok')return undefined;if(!l.run)l.run=Date.now();const h=tkNow(l);const lvl=Math.min(4,Math.floor(h/10));return{lvl,prog:lvl>=4?1:(h-10*lvl)/10,h:Math.round(h*10)/10,ready:false,sp:l.sp||0}};setInterval(()=>{let ch=0;const touched=[];Object.values(R).forEach(r=>{if(!r.lid||!r.m.length)return;const l=DB.lregs[r.lid];if(l&&l.st==='ok'){l.hrs+=1/60;ch=1;touched.push(r)}});if(ch){save();touched.forEach(r=>pushRoom(r));pushLobbies()}},60e3);
const spOn=r=>!!(r.spUntil&&r.spUntil>Date.now());const view=r=>({id:r.id,n:r.n,sc:r.scn?'🎭 '+r.scn:r.sc,scr:r.scRoles||null,max:r.max,mg:r.mg,rk:r.rk,tk:tkOf(r),sp:spOn(r)?1:0,spLeft:spOn(r)?r.spUntil-Date.now():0,th:r.th||0,m:r.m.map(x=>({n:x.n,eq:DB.users[x.n].eq,rd:x.rd?1:0}))});
const lobbies=()=>{const open=Object.values(R).filter(r=>!r.rk||r.g).sort((a,b)=>(spOn(b)?1:0)-(spOn(a)?1:0)).map(r=>({id:r.id,lid:r.lid,n:r.n,sc:r.scn?'🎭 '+r.scn:r.sc,c:r.m.length,max:r.max,mg:r.mg,live:r.g?1:0,tk:tkOf(r),sp:spOn(r)?1:0,th:r.th||0}));const used=new Set(Object.values(R).map(r=>r.lid).filter(Boolean));const regs=Object.values(DB.lregs).filter(l=>l.st==='ok'&&!used.has(l.id)).map(l=>({id:'reg:'+l.id,lid:l.id,n:l.name,sc:'تکاور',c:0,max:10,mg:l.owner,live:0,tk:tkOf({lid:l.id}),reg:1}));return open};
const pushRoom=r=>{const o=Object.assign({t:'room'},view(r));bc(r,o);(r.gh||[]).forEach(n=>to(n,o))};
let lbT;const pushLobbies=()=>{clearTimeout(lbT);lbT=setTimeout(()=>{const l=lobbies();for(const n in conns)if(!R[where[n]])conns[n].send({t:'lobbies',list:l})},250)};
const mkRoom=(n,sc,mg,rk)=>{const id='L'+RID++;return R[id]={id,n,sc,max:sc==='اختصاصی'?7:10,mg,m:[],bl:[],g:null,rk:rk?1:0}};
function leave(c){const u=c.name,r=R[where[u]];if(!r)return;delete where[u];if(r.g)return;r.m=r.m.filter(x=>x.n!==u);if(!r.m.length){if(!r.lid)delete R[r.id]}else{if(r.mg===u)r.mg=r.m[0].n;pushRoom(r)}pushLobbies()}
function join(c,id){if(typeof id==='string'&&id.startsWith('reg:')){const l=DB.lregs[id.slice(4)];if(!l||l.st!=='ok')return c.send({t:'err',e:'این لابی دیگر فعال نیست'});let rr=Object.values(R).find(x=>x.lid===l.id);if(!rr){rr=mkRoom(l.name,'تکاور',l.owner,0);rr.lid=l.id}id=rr.id}
const u=c.name,r=R[id],cur=R[where[u]];if(!r)return c.send({t:'err',e:'لابی پیدا نشد'});if(cur===r)return pushRoom(r);if(cur&&cur.g)return c.send({t:'err',e:'تا پایان بازی نمی‌توانی وارد لابی دیگری شوی'});
 if(r.g)return c.send({t:'err',e:'بازی در این لابی شروع شده'});if(r.bl.includes(u))return c.send({t:'err',e:'از این لابی مسدود شده‌ای'});if(r.m.length>=r.max)return c.send({t:'err',e:'لابی پر است'});
 leave(c);r.m.push({n:u,rd:0});where[u]=id;hist(u,r);pushRoom(r);pushLobbies()}
function drop(c){if(!c.name||conns[c.name]!==c)return;delete conns[c.name];const i=Q.indexOf(c.name);if(i>-1)Q.splice(i,1);const r=R[where[c.name]];if(c.watch&&R[c.watch]){const w=R[c.watch];w.w=(w.w||[]).filter(n=>n!==c.name);w.gh=(w.gh||[]).filter(n=>n!==c.name)}if(r&&!r.g)leave(c)}
setInterval(()=>{for(const id in R){const r=R[id];if(!r.m.some(x=>conns[x.n]&&where[x.n]===id)&&!r.lid){if(r.g)r.g.x=1;r.m.forEach(x=>{if(where[x.n]===id)delete where[x.n]});delete R[id];pushLobbies()}}},30000);

/* ---------- ورود و پیام‌ها ---------- */
function hello(c,m){const name=clean(m.name).slice(0,16);
 if(!name||name==='بازیکن'||(name in Object.prototype))return c.fatal('اول از پروفایل (✎ کنار نام) یک نام دلخواه بگذار، بعد دوباره وصل شو');
 const ipOwner=c.ip&&DB.vipIp[c.ip];if(DB.vip[name]||(ipOwner&&(ipOwner===1||DB.vip[ipOwner]))){c.send({t:'banned',vip:1});return c.sock.end()}
 let u=DB.users[name];if(u&&u.tok!==m.tok)return c.fatal('این نام قبلاً توسط شخص دیگری گرفته شده؛ نام دیگری انتخاب کن');
 if(!u)u=DB.users[name]={tok:crypto.randomBytes(12).toString('hex'),coins:500,gems:2000,owned:['a0'],eq:{a:'a0',f:'',c:''},last:0,wins:0,games:0};
 u.ip=c.ip;if(m.ph&&/^09\d{9}$/.test(String(m.ph)))u.phone=String(m.ph);if((DB.bans[name]||0)>Date.now()){c.send({t:'banned'});return c.sock.end()}
 const old=conns[name];if(old&&old!==c){old.send({t:'err',e:'از دستگاه دیگری وارد شدی',fatal:1});old.sock.end()}
 c.name=name;conns[name]=c;
 if(m.eq&&typeof m.eq==='object')u.eq=okEq(u,m.eq);
 const inbox=u.inbox||[];u.inbox=[];save();
 c.send({t:'hi',v:66,sc2:1,sc3:1,rank:rankOf(u),deals:dealsInfo(),imgs:ownImgs(u),mgrs:DB.mgrs||[],tok:u.tok,u:{coins:u.coins,gems:u.gems,owned:u.owned,fcLeft:Math.max(0,(u.fc||0)-Date.now())},lobbies:lobbies(),ice:ICE,inbox,sup:DB.sups.includes(name)?1:0});
 const r=R[where[name]];if(r){c.send(Object.assign({t:'room'},view(r)));if(r.g){sendRole(r,name);r.g.P.filter(p=>!p.ok).forEach(p=>c.send({t:'dead',n:p.n,r:p.r,why:'قبلاً'}))}}}
function msg(c,txt){if(txt.length>400000)return;const now=Date.now();if(now-(c.rw||0)>1000){c.rw=now;c.rc=0}if(++c.rc>90)return;let m;try{m=JSON.parse(txt)}catch(e){return}if(!m||typeof m.t!=='string')return;if(m.t==='hello')return hello(c,m);
 const u=c.name;if(!u)return;const r=R[where[u]],d=DB.users[u];
 switch(m.t){
 case 'spk':{const sup=c.adm||DB.sups.includes(u);const r=R[where[u]]||(sup&&c.watch?R[c.watch]:null);if(!r)break;bc(r,{t:'spk',n:u,on:m.on?1:0});break}
 case 'create':{if(m.sc==='پازپرس')m.sc='بازپرس';if(!SC[m.sc])return c.send({t:'err',e:'نوع لابی نامعتبر است'});let scs=null;if(m.sc==='اختصاصی'){if(Array.isArray(m.scr)){const rl=m.scr.map(x=>String(x)).slice(0,40),bad=scCheck(rl);if(bad)return c.send({t:'err',e:bad});scs={roles:rl,name:clean(m.scn)||'سناریو'}}else{scs=DB.scs[m.scid];if(!scs||scs.owner!==u)return c.send({t:'err',e:'اول یک سناریو بساز و انتخاب کن'})}}if((DB.lbBan[u]||0)>Date.now())return c.send({t:'err',e:'مدیر لابی تو را حذف کرده؛ تا '+Math.ceil((DB.lbBan[u]-Date.now())/36e5)+' ساعت دیگر نمی‌توانی لابی بسازی'});const n=clean(m.n);if(!n)return c.send({t:'err',e:'نام لابی را بنویسید'});if(r&&r.g)return c.send({t:'err',e:'تا پایان بازی نمی‌توانی لابی بسازی'});const reg=Object.values(DB.lregs).find(l=>l.name===n&&l.st==='ok');if(reg&&reg.owner!==u)return c.send({t:'err',e:'این نام لابی ثبت‌شده و مال شخص دیگری است'});leave(c);const passOn=(d.spPass||0)>Date.now();if(m.sp&&!passOn)return c.send({t:'err',e:'لابی ویژه فعال نیست؛ اول تیک لابی ویژه را بزن و ۱۲۰ جم بده'});const nr=mkRoom(n,m.sc,u,0);if(scs){nr.scRoles=scs.roles.slice();nr.scn=scs.name;nr.max=scs.roles.length}nr.sp=m.sp?1:0;nr.spUntil=m.sp?d.spPass:0;nr.th=m.sp?Math.max(0,Math.min(99,+m.th||0)):0;if(reg){nr.lid=reg.id;reg.made=1;reg.sc=m.sc;if(scs){reg.scr=scs.roles.slice();reg.scn=scs.name}else{delete reg.scr;delete reg.scn}save()}nr.m.push({n:u,rd:0});where[u]=nr.id;hist(u,nr);pushRoom(nr);pushLobbies();break}
 case 'join':join(c,m.id);break;
 case 'leave':leave(c);break;
 case 'live':c.send({t:'lobbies',list:lobbies()});break;
 case 'members':{if(!c.adm)break;c.send({t:'members',list:Object.keys(DB.users).map(n=>({n,online:!!conns[n],games:DB.users[n].games||0,wins:DB.users[n].wins||0,av:(DB.users[n].eq&&DB.users[n].eq.a)||'a0'})).sort((a,b)=>b.online-a.online)});break}
 case 'member':{if(!c.adm)break;const n=clean(m.n),t=DB.users[n];if(!t)break;c.send({t:'member',d:{n,phone:t.phone||'ثبت نشده',av:(t.eq&&t.eq.a)||'a0',games:t.games||0,wins:t.wins||0,coins:t.coins,gems:t.gems,online:!!conns[n],lobbies:[...new Set(t.hist||[])].reverse()}});break}
  case 'rkq':{if(!conns[u]||where[u]||RQ.includes(u)===true&&false)break;if(!RQ.includes(u))RQ.push(u);rkNotify();break}
 case 'rkcancel':{RQ=RQ.filter(x=>x!==u);c.send({t:'rkleft'});break}
 case 'ltk2':{if(!c.adm)break;c.send({t:'ltk2',list:Object.values(DB.lregs).filter(l=>l.st==='ok').map(l=>({id:l.id,name:l.name,owner:l.owner,st:l.st,by:l.by}))});break}
 case 'lrename':{const l=DB.lregs[m.id];if(!l||l.owner!==u||l.by==='admin')return c.send({t:'err',e:'این نام قابل ویرایش نیست'});const n=clean(m.name);if(!n)return c.send({t:'err',e:'نام لابی را بنویس'});if(Object.values(DB.lregs).some(x=>x.name===n&&x.id!==l.id&&x.st!=='rej'))return c.send({t:'err',e:'این نام قبلاً ثبت شده'});l.name=n;save();c.send({t:'info',e:'✅ نام ویرایش شد'});c.send({t:'lmine2',list:Object.values(DB.lregs).filter(x=>x.owner===u).map(x=>({id:x.id,name:x.name,st:x.st,hrs:Math.round(x.hrs*10)/10,lvl:Math.min(4,Math.floor(x.hrs/10))})),spLeft:Math.max(0,(DB.users[u].spPass||0)-Date.now())});break}
 case 'lgive':{if(!c.adm)break;const to_=clean(m.to);const n=clean(m.name);if(!to_||!n||!DB.users[to_])return c.send({t:'err',e:'کاربر یا نام نامعتبر است'});if(Object.values(DB.lregs).some(x=>x.name===n&&x.st!=='rej'))return c.send({t:'err',e:'این نام قبلاً ثبت شده'});const id='R'+Date.now().toString(36)+Math.floor(Math.random()*1e3);DB.lregs[id]={id,name:n,owner:to_,st:'ok',hrs:0,lvl:0,sp:0,by:'admin',ts:Date.now()};save();c.send({t:'info',e:'✅ تیک «'+n+'» برای '+to_+' فعال شد'});to(to_,{t:'info',e:'🏷 مدیر تیک «'+n+'» را برای تو فعال کرد'});break}
 case 'lrevoke':{if(!c.adm)break;const l=DB.lregs[m.id];if(!l)return c.send({t:'err',e:'این تیک پیدا نشد'});const owner=l.owner;delete DB.lregs[m.id];save();c.send({t:'info',e:'✅ تیک «'+l.name+'» گرفته شد'});to(owner,{t:'info',e:'تیک «'+l.name+'» توسط مدیر گرفته شد'});break}
 case 'lmine':case 'lmine2':c.send({t:m.t==='lmine2'?'lmine2':'lmine',list:Object.values(DB.lregs).filter(l=>l.owner===u).map(l=>({id:l.id,name:l.name,st:l.st,by:l.by,hrs:Math.round(l.hrs*10)/10,lvl:Math.min(4,Math.floor(l.hrs/10))})),spLeft:Math.max(0,(d.spPass||0)-Date.now())});break;
 case 'ltickset':{if(!c.adm)break;const l=DB.lregs[m.id];if(l&&l.st==='ok'){const lv=Math.max(0,Math.min(4,+m.lvl||0));l.hrs=lv*10;l.lvl=lv;save();Object.values(R).forEach(r=>{if(r.lid===m.id)pushRoom(r)});pushLobbies();c.send({t:'info',e:'تیک به مرحله '+lv+' رفت ✅'})}break}
 case 'lreg':{if((DB.lbBan[u]||0)>Date.now())return c.send({t:'err',e:'مدیر لابی تو را حذف کرده؛ تا '+Math.ceil((DB.lbBan[u]-Date.now())/36e5)+' ساعت دیگر نمی‌توانی لابی ثبت کنی'});const n=clean(m.name);if(!n)return c.send({t:'err',e:'نام لابی را بنویسید'});if(Object.values(DB.lregs).some(l=>l.name===n&&l.st!=='rej'))return c.send({t:'err',e:'این نام قبلاً ثبت شده'});const id='R'+Date.now().toString(36)+Math.floor(Math.random()*99);DB.lregs[id]={id,name:n,owner:u,st:'pending',hrs:0,lvl:0,sp:0};save();c.send({t:'info',e:'⏳ درخواست برای مدیر ارسال شد'});break}
 case 'lbanlist':{if(!c.adm)break;c.send({t:'lbanlist',list:Object.entries(DB.lbBan||{}).filter(e=>e[1]>Date.now()).map(e=>({n:e[0],left:e[1]-Date.now()}))});break}
 case 'lunbanx':{if(!c.adm)break;const nm=clean(m.n).slice(0,16);if(DB.lbBan&&nm)delete DB.lbBan[nm];save();c.send({t:'lbanlist',list:Object.entries(DB.lbBan||{}).filter(e=>e[1]>Date.now()).map(e=>({n:e[0],left:e[1]-Date.now()}))});break}
 case 'lregs':case 'lapprove':case 'lreject':case 'lunver':case 'lhrs':case 'lpromos':case 'lpromote':case 'ltickers':case 'ltickrm':{if(!c.adm)break;const l=DB.lregs[m.id];
  if(l){if(m.t==='lapprove'){l.st='ok';l.run=l.run||Date.now();try{to(l.owner,{t:'info',e:'✅ لابی «'+l.name+'» تأیید شد'});to(l.owner,{t:'lmine2',list:Object.values(DB.lregs).filter(x=>x.owner===l.owner).map(x=>({id:x.id,name:x.name,st:x.st,hrs:Math.round(x.hrs*10)/10,lvl:Math.min(4,Math.floor(x.hrs/10))})),spLeft:Math.max(0,((DB.users[l.owner]||{}).spPass||0)-Date.now())})}catch(e){}}else if(m.t==='lreject')l.st='rej';else if(m.t==='lunver'||m.t==='ltickrm')l.st='revoked';else if(m.t==='lhrs')l.hrs+=Math.max(0,+m.h||0);else if(m.t==='lpromote'&&l.lvl<4&&l.hrs>=20*(l.lvl+1))l.lvl++;save()}
  const all=Object.values(DB.lregs),row=l=>({id:l.id,name:l.name,owner:l.owner,st:l.st,hrs:Math.round(l.hrs*10)/10,lvl:Math.min(4,Math.floor(l.hrs/10)),sp:l.sp});
  if(m.t==='lpromos'||m.t==='lpromote')c.send({t:'lpromos',list:all.filter(l=>l.st==='ok'&&l.lvl<4&&l.hrs>=20*(l.lvl+1)).map(row)});
  else if(m.t==='ltickrm')c.send({t:'info',e:'تیک لابی برای همیشه گرفته شد ✅'});if(m.t==='ltickrm')Object.values(R).forEach(r=>{if(r.lid===m.id)pushRoom(r)});
  else if(m.t==='ltickers')c.send({t:'ltickers',list:all.filter(l=>l.st==='ok').map(row)});
  else c.send({t:'lregs',list:all.map(row)});
  pushLobbies();break}
 case 'eq':if(m.eq&&typeof m.eq==='object'){const q0={a:String(m.eq.a||'a0').slice(0,30),f:String(m.eq.f||'').slice(0,30),c:String(m.eq.c||'').slice(0,30)};d.eq=okEq(d,m.eq);if(d.eq.a!==q0.a||d.eq.f!==q0.f||d.eq.c!==q0.c)c.send({t:'bal',coins:d.coins,gems:d.gems,owned:d.owned,eq:d.eq});if(r&&!r.g)pushRoom(r)}break;
 case 'sync':{const ng=Math.min(d.gems,Math.max(0,Math.floor(+m.gems)||0)),nc=Math.min(d.coins,Math.max(0,Math.floor(+m.coins)||0));d.cg=(d.cg||0)+(d.gems-ng);d.gems=ng;d.coins=nc;let bad=0;if(Array.isArray(m.owned))m.owned.slice(0,400).forEach(x=>{x=String(x).slice(0,30);if(d.owned.includes(x))return;if(FREEI[x]){d.owned.push(x);return}const pr=dealPrice(x);if(pr&&d.cg>=pr){d.cg-=pr;d.owned.push(x)}else bad=1});save();if(bad)c.send({t:'bal',coins:d.coins,gems:d.gems,owned:d.owned,eq:d.eq});break}
 case 'scmine':{c.send(scList(u));break}
 case 'scsave':{const nm=clean(m.name),rl=Array.isArray(m.roles)?m.roles.map(x=>String(x)).slice(0,40):[];if(!nm)return c.send({t:'scres',ok:0,msg:'برای سناریو یک نام بنویس'});const bad=scCheck(rl);if(bad)return c.send({t:'scres',ok:0,msg:bad});const mine=Object.values(DB.scs).filter(x=>x.owner===u);let ex=null;if(m.id){ex=DB.scs[m.id];if(!ex||ex.owner!==u)return c.send({t:'scres',ok:0,msg:'سناریو پیدا نشد'});if(mine.some(x=>x.name===nm&&x.id!==ex.id))return c.send({t:'scres',ok:0,msg:'سناریوی دیگری با این نام داری'})}else ex=mine.find(x=>x.name===nm);if(!ex&&mine.length>=12)return c.send({t:'scres',ok:0,msg:'حداکثر ۱۲ سناریو می‌توانی داشته باشی؛ یکی را حذف کن'});const id=ex?ex.id:'S'+crypto.randomBytes(5).toString('hex');DB.scs[id]={id,owner:u,name:nm,roles:rl,ts:Date.now()};save();c.send({t:'scres',ok:1,id,name:nm,edit:ex?1:0,msg:ex?'✅ سناریو «'+nm+'» ذخیره شد':'✅ سناریو «'+nm+'» ساخته شد'});c.send(scList(u));break}
 case 'scdel':{const x=DB.scs[m.id];if(x&&x.owner===u){delete DB.scs[m.id];save()}c.send(scList(u));break}
 case 'buysp':{const now=Date.now();if((d.spPass||0)>now){c.send({t:'spres',ok:1,left:d.spPass-now,gems:d.gems});break}if((d.gems||0)<120){c.send({t:'spres',ok:0,msg:'جم کافی نیست (۱۲۰ جم لازم است)',gems:d.gems});break}d.gems-=120;d.spPass=now+48*36e5;save();c.send({t:'spres',ok:1,left:48*36e5,gems:d.gems,msg:'✅ ۱۲۰ جم پرداخت شد؛ ۴۸ ساعت لابی ویژه فعال شد'});break}
 case 'freecoin':{const now=Date.now();if((d.fc||0)>now){c.send({t:'fcres',ok:0,left:d.fc-now,coins:d.coins});break}d.coins=(d.coins||0)+300;d.fc=now+48*36e5;save();c.send({t:'fcres',ok:1,left:48*36e5,coins:d.coins});break}
 case 'ready':{if(!r||r.g)break;const x=r.m.find(y=>y.n===u);x.rd=x.rd?0:1;pushRoom(r);if(r.m.length>=(r.rk?r.max:Math.min(r.max,MINP))&&r.m.every(y=>y.rd))start(r);break}
 case 'kick':case 'block':case 'give':{if(!r||r.g||r.mg!==u||m.n===u)break;const x=r.m.find(y=>y.n===m.n);if(!x)break;
  if(m.t==='give')r.mg=m.n;else{r.m=r.m.filter(y=>y!==x);delete where[m.n];if(m.t==='block')r.bl.push(m.n);to(m.n,{t:'kicked',why:m.t==='block'?'از لابی مسدود شدی':'از لابی اخراج شدی'})}pushRoom(r);pushLobbies();break}
 case 'rtc':{const wr=R[c.watch];if((r&&(where[m.to]===r.id||(r.w||[]).includes(m.to)))||(wr&&where[m.to]===wr.id))to(m.to,{t:'rtc',from:u,d:m.d});break}
 case 'watch':case 'ghost':{const t=R[m.id],sup=c.adm||DB.sups.includes(u);if(!t)return c.send({t:'err',e:'بازی پیدا نشد'});if(m.t==='ghost'&&!sup)break;
  if(!t.g){return c.send({t:'wstate',running:0,ghost:0})}
  c.watch=t.id;t.w=t.w||[];if(!t.w.includes(u))t.w.push(u);
  c.send({t:'wstate',ghost:m.t==='ghost'?1:0,running:1,id:t.id,sc:t.sc,sup:sup?1:0,p:t.g.P.map(p=>({n:p.n,r:sup?p.r:undefined,ok:p.ok,eq:DB.users[p.n].eq}))});if(sup&&m.t==='ghost')t.m.forEach(x=>{if(x.n!==u)to(x.n,{t:'supin',id:t.id,n:u})});
  if(sup){const ns=t.g.P.map(p=>p.n);ns.forEach(n=>to(n,{t:'vcx',names:[u]}));c.send({t:'vcx',names:ns})}break}
 case 'unwatch':{const t=R[m.id];if(t){t.w=(t.w||[]).filter(n=>n!==u);t.gh=(t.gh||[]).filter(n=>n!==u);t.m.forEach(x=>{if(x.n!==u)to(x.n,{t:'supout',id:t.id,n:u})})}c.watch=null;break}
 case 'sreturn':case 'srej':case 'scut':{const t=R[m.id],g=t&&t.g;if(!g||!(c.adm||DB.sups.includes(u)))break;const p=g.P.find(x=>x.n===m.n);if(!p)break;if(m.t==='sreturn'){if(p.kicked){p.kicked=0;p.ok=1;bc(t,{t:'say',text:p.n+' توسط ناظر به بازی برگشت'});to(p.n,{t:'info',e:'ناظر تو را به بازی برگرداند'})}}else if(g.tk&&g.tk.n===p.n){bc(t,{t:'say',text:p.n+(m.t==='srej'?' رد شد':' صحبتش قطع شد')});g.tk.f()}break}
 case 'smic':case 'pause':case 'skick':case 'endgame':{const t=R[m.id],g=t&&t.g;if(!g||!(c.adm||DB.sups.includes(u)))break;const p=g.P.find(x=>x.n===m.n);
  if(m.t==='smic'){if(p)to(p.n,{t:'mic',on:m.on?1:0,by:u})}
  else if(m.t==='pause')g.paused=m.v?1:0;
  else if(m.t==='skick'){if(p&&p.ok){p.kicked=1;bc(t,{t:'say',text:p.n+' توسط ناظر از بازی اخراج شد'});kill(t,p,'اخراج')}}
  else{g.x=1;bc(t,{t:'end',w:'ناظر بازی را پایان داد',roles:g.P.map(x=>({n:x.n,r:x.r,ok:x.ok}))});t.g=null;t.w=[];t.m=t.m.filter(x=>where[x.n]===t.id);t.m.forEach(x=>x.rd=0);if(!t.m.length){if(!t.lid)delete R[t.id]}else pushRoom(t);pushLobbies()}break}
 case 'lkick':{const t=R[m.id];if(!t||!(c.adm||DB.sups.includes(u)))break;const x=t.m.find(y=>y.n===m.n);if(!x)break;
  if(t.g){const p=t.g.P.find(q=>q.n===m.n);if(p&&p.ok){p.kicked=1;bc(t,{t:'say',text:p.n+' توسط ناظر از بازی اخراج شد'});kill(t,p,'اخراج')}}
  else{t.m=t.m.filter(y=>y!==x)}delete where[m.n];to(m.n,{t:'kicked',why:'توسط مدیر از لابی اخراج شدی'});if(!t.g)pushRoom(t);pushLobbies();break}
 case 'dellobby':{const t=R[m.id];if(!t||!(c.adm||DB.sups.includes(u)))break;if(t.g)t.g.x=1;
  const reg=t.lid&&DB.lregs[t.lid];
  t.m.forEach(x=>{if(where[x.n]===t.id){delete where[x.n];to(x.n,{t:'kicked',why:'لابی توسط مدیر حذف شد'})}});(t.gh||[]).concat(t.w||[]).forEach(n=>{if(n!==u)to(n,{t:'kicked',why:'لابی حذف شد'})});
  if(t.lid)delete DB.lregs[t.lid];(t.w||[]).length=0;t.g=null;delete R[t.id];if(reg){const ow=reg.owner;to(ow,{t:'lmine2',list:Object.values(DB.lregs).filter(x=>x.owner===ow).map(x=>({id:x.id,name:x.name,st:x.st,hrs:Math.round(x.hrs*10)/10,lvl:Math.min(4,Math.floor(x.hrs/10))})),spLeft:Math.max(0,((DB.users[ow]||{}).spPass||0)-Date.now())})}save();pushLobbies();c.send({t:'info',e:'🗑 لابی کاملاً حذف شد'});break}
 case 'ltick0':{if(!c.adm)break;const t=R[m.id];if(!t||!t.lid||!DB.lregs[t.lid])return c.send({t:'info',e:'این لابی تیک ندارد'});DB.lregs[t.lid].st='revoked';save();pushRoom(t);pushLobbies();c.send({t:'info',e:'🏅 تیک این لابی برای همیشه گرفته شد'});break}
 case 'supset':case 'supdel':{if(!c.adm)break;const n=clean(m.n);DB.sups=DB.sups.filter(x=>x!==n);if(m.t==='supset')DB.sups.push(n);save();to(n,{t:'info',e:m.t==='supset'?'🔎 شما ناظر شدید؛ دوباره وارد شوید':'نظارت شما برداشته شد'});c.send({t:'info',e:'انجام شد ✅'});break}
 case 'skip':if(r&&r.g&&r.g.tk&&r.g.tk.n===u)r.g.tk.f();break;
 case 'night':case 'vote':{const g=r&&r.g,w=g&&g.w;if(!w||!w.who.includes(u)||u in w.got)break;const a=g.P.find(p=>p.n===u),t=g.P.find(p=>p.n===m.to);if(!a||!a.ok||!t||!t.ok||!w.ok(a,t))break;w.got[u]=t.n;if(w.who.every(n=>n in w.got))w.fin();break}
 case 'shoot':{const g=r&&r.g;if(!g||g.night)break;const a=g.P.find(p=>p.n===u),t=g.P.find(p=>p.n===m.to);if(!a||!a.ok||!a.gun||!t||!t.ok||t===a)break;a.gun=0;bc(r,{t:'shot'});bc(r,{t:'say',text:'صدای شلیک! '+t.n+' ('+t.r+') با تفنگ کشته شد'});kill(r,t,'تفنگ');break}
 case 'who':{const n=clean(m.n),t=DB.users[n];c.send({t:'who',ok:!!t&&n!==u,n,eq:t&&t.eq,kind:m.kind,amt:Math.floor(+m.amt)||0});break}
 case 'xfer':{const k=m.kind==='gems'?'gems':'coins',a=Math.floor(+m.amt),tn=clean(m.to),t=DB.users[tn];
  if(!t||tn===u||!(a>0))return c.send({t:'err',e:'انتقال ممکن نیست'});if(d[k]<a)return c.send({t:'err',e:'موجودی کافی نیست'});
  d[k]-=a;t[k]+=a;note(tn,u+' مقدار '+a+(k==='gems'?' جم 💎':' سکه 🪙')+' برایت فرستاد 🎁');save();c.send({t:'bal',coins:d.coins,gems:d.gems,msg:'✅ '+a+(k==='gems'?' جم':' سکه')+' به '+tn+' منتقل شد'});break}
 case 'emo':{if(!r||!EMO.includes(m.e))break;const now=Date.now();if(c.le&&now-c.le<800)break;c.le=now;bc(r,{t:'emo',n:u,e:m.e});break}
 case 'a2':if(c.adm)a2(c,m);else c.send({t:'err',e:'اول رمز مدیر را وارد کن'});break;
 case 'deals':c.send({t:'deals',deals:dealsInfo()});break;
 case 'img':{const iid=String(m.id||'').slice(0,30);if(DB.cimg&&DB.cimg[iid])c.send({t:'imgs',map:{[iid]:DB.cimg[iid]}});break}
 case 'report':{const to=clean(m.to).slice(0,16),why=clean(m.why).slice(0,60);if(!to||to===u||!DB.users[to]||!why)return c.send({t:'err',e:'گزارش نامعتبر است'});DB.reps=DB.reps||[];const nw=Date.now();if(DB.reps.filter(x=>x.from===u&&nw-x.ts<36e5).length>=5)return c.send({t:'err',e:'در یک ساعت بیش از ۵ گزارش نمی‌شود'});if(DB.reps.some(x=>x.from===u&&x.to===to&&nw-x.ts<6e5))return c.send({t:'err',e:'این بازیکن را به‌تازگی گزارش کرده‌ای'});DB.reps.push({id:'G'+crypto.randomBytes(4).toString('hex'),from:u,to,why,ts:nw,room:r?r.n:''});if(DB.reps.length>300)DB.reps.splice(0,DB.reps.length-300);save();c.send({t:'info',e:'🚩 گزارش ثبت شد؛ مدیر بررسی می‌کند'});break}
 case 'league':c.send({t:'league',list:Object.entries(DB.lg).sort((a,b)=>b[1]-a[1]).slice(0,100).map(e=>({n:e[0],lp:e[1],a:(DB.users[e[0]]&&DB.users[e[0]].eq&&DB.users[e[0]].eq.a)||'a0'})),my:DB.lg[u]||0,rank:rankOf(u),total:Object.values(DB.lg).filter(x=>x>0).length});break;
 case 'rankq':{if(Q.includes(u)||(r&&r.g))break;leave(c);Q.push(u);
  if(Q.length>=10){const ps=Q.splice(0,10),nr=mkRoom('امتیازی',rnd(['تکاور','بازپرس']),ps[0],1);ps.forEach(n=>{nr.m.push({n,rd:1});where[n]=nr.id});pushRoom(nr);setTimeout(()=>R[nr.id]&&start(nr),1500)}else Q.forEach(n=>to(n,{t:'rankq',c:Q.length}));break}
 case 'rankc':{const i=Q.indexOf(u);if(i>-1)Q.splice(i,1);break}
 case 'admin':{const AK=c.ip||'?',AT=ADMTRY[AK]||(ADMTRY[AK]={n:0,t:0});if(Date.now()<AT.t){c.send({t:'err',e:'تلاش بیش از حد؛ ۱۵ دقیقه دیگر دوباره امتحان کن'});break}if(m.pass!==ADMIN&&++AT.n>=6){AT.t=Date.now()+15*60000;AT.n=0}}if(m.pass===ADMIN){c.adm=1;DB.mgrs=DB.mgrs||[];if(u&&!DB.mgrs.includes(u)){DB.mgrs.push(u);save()}Object.keys(conns).forEach(n=>to(n,{t:'mgrs',list:DB.mgrs}));c.send({t:'admin'})}else c.send({t:'err',e:'رمز اشتباه است'});break;
 case 'ban':if(c.adm||(DB.sups.includes(u)&&+m.days>=1&&+m.days<=365))admin(c,m);break;
 case 'coinsAll':case 'gemsAll':case 'coinsTo':case 'gems':case 'vipban':case 'unban':case 'banlist':if(c.adm)admin(c,m);break}}
function hist(n,r){const t=DB.users[n];if(!t)return;t.hist=t.hist||[];t.hist.push(r.n);if(t.hist.length>80)t.hist.shift();save()}
const EMO=['👍','👎','😂','😎','😡','😱','😭','🤔','🔥','💖','👏','🤫','😈','🔍','💀','🙏','😴','🤝'];
function note(n,txt){const t=DB.users[n];if(!t)return;if(conns[n])to(n,{t:'bal',coins:t.coins,gems:t.gems,owned:t.owned,eq:t.eq,msg:txt});else(t.inbox=t.inbox||[]).push(txt)}
function a2(c,m){
 const k=m.a,n=clean(m.n),t=DB.users[n];
 if(k==='banlist'){const now=Date.now();return c.send({t:'a2',k:'banlist',list:Object.entries(DB.bans).filter(e=>e[1]>now).map(e=>({n:e[0],until:e[1],vip:!!DB.vip[e[0]]}))})}
 if(k==='leagueend'){const top=Object.entries(DB.lg).sort((a,b)=>b[1]-a[1]).slice(0,3),pz=[[1000,500],[500,300],[250,150]];
  const won=top.map((e,i)=>{const u=DB.users[e[0]];if(u){u.gems+=pz[i][0];u.coins+=pz[i][1];note(e[0],'🏆 جایزه‌ی پایان هفته لیگ: '+pz[i][0]+' جم و '+pz[i][1]+' سکه (رتبه '+(i+1)+')')}return{n:e[0],lp:e[1],rank:i+1}});
  DB.lg={};save();return c.send({t:'a2',k:'league',list:won})}
 if(k==='reports'){return c.send({t:'a2',k:'reports',list:(DB.reps||[]).slice(-40).reverse()})}
  if(k==='repdel'){DB.reps=(DB.reps||[]).filter(x=>x.id!==m.id);save();return c.send({t:'a2',k:'reports',list:(DB.reps||[]).slice(-40).reverse()})}
  if(k==='gimg'){if(!t)return c.send({t:'err',e:'بازیکن پیدا نشد'});const im=String(m.img||'');if(!/^data:image\/(webp|png|jpeg);base64,[A-Za-z0-9+\/=]+$/.test(im)||im.length>300000)return c.send({t:'err',e:'تصویر نامعتبر یا خیلی بزرگ است'});DB.cimg=DB.cimg||{};const gid='cu'+crypto.randomBytes(4).toString('hex');DB.cimg[gid]=im;t.owned.push(gid);save();if(conns[n])to(n,{t:'grant',id:gid,img:im,msg:'آواتار تصویری از طرف مدیر'});else(t.inbox=t.inbox||[]).push('🎁 مدیر یک آواتار تصویری برایت فرستاد');return c.send({t:'a2',k:'ok',msg:'تصویر به '+n+' داده شد'})}
  if(k==='codegift'){const id=String(m.code||'').trim().toUpperCase().replace(/^MF-/,'').toLowerCase();
  if(!t)return c.send({t:'err',e:'بازیکن پیدا نشد'});if(!/^a\d+$/.test(id))return c.send({t:'err',e:'کد نامعتبره؛ مثل MF-A22'});
  if(!t.owned.includes(id))t.owned.push(id);note(n,'🎁 مدیر یک آواتار برایت فرستاد');save();return c.send({t:'a2',k:'ok',msg:'آواتار '+id+' به '+n+' داده شد'})}
 if(!t)return c.send({t:'err',e:'بازیکن پیدا نشد'});
 if(k==='info'){const o=t.owned||[],cnt=p=>o.filter(x=>x[0]===p).length,
   lobbies=Object.values(DB.lregs).filter(l=>l.owner===n).map(l=>({name:l.name,st:l.st,hrs:Math.round(l.hrs*10)/10}));
  return c.send({t:'a2',k:'info',d:{n,coins:t.coins,gems:t.gems,avatars:cnt('a'),frames:cnt('f'),crowns:cnt('c'),games:t.games||0,wins:t.wins||0,lp:DB.lg[n]||0,lobbies,ban:(DB.bans[n]||0)>Date.now()?DB.bans[n]:null,vip:!!DB.vip[n]}})}
 if(k==='reset'){t.coins=0;t.gems=0;t.owned=['a0'];t.eq={a:'a0',f:'',c:''};note(n,'⚠️ اکانتت توسط مدیر کاملاً صفر شد');save();return c.send({t:'a2',k:'ok',msg:'اکانت «'+n+'» صفر شد'})}
 if(k==='coins'||k==='gems'){const v=Math.floor(+m.v)||0;t[k]=Math.max(0,t[k]+v);note(n,(v>=0?'🎁 مدیر '+v:'➖ مدیر '+(-v))+(k==='gems'?' جم':' سکه')+' به حسابت '+(v>=0?'اضافه':'کم')+' کرد');save();return c.send({t:'a2',k:'ok',msg:(k==='gems'?'جم':'سکه')+' «'+n+'» تغییر کرد: '+t[k]})}
 if(k==='unvip'){if(!DB.vip[n])return c.send({t:'err',e:'این کاربر بن VIP نیست'});delete DB.vip[n];delete DB.bans[n];for(const ip of Object.keys(DB.vipIp)){if(DB.vipIp[ip]===n||DB.vipIp[ip]===1&&(ip===t.ip||!t.ip))delete DB.vipIp[ip]}if(t.ip)delete DB.vipIp[t.ip];save();return c.send({t:'a2',k:'ok',msg:'بن VIP «'+n+'» برداشته شد'})}
 if(k==='ban')return admin(c,{t:'ban',n,days:m.days});
 if(k==='vipban')return admin(c,{t:'vipban',n});
 if(k==='unban')return admin(c,{t:'unban',n});
}
function admin(c,m){const t=DB.users[m.n];
 if(m.t==='coinsAll'||m.t==='gemsAll'){const k=m.t==='gemsAll'?'gems':'coins',v=Math.floor(+m.v)||0;if(v<=0)return c.send({t:'err',e:'مقدار نامعتبر'});for(const n in DB.users){DB.users[n][k]+=v;note(n,'🎁 مدیر '+v+(k==='gems'?' جم':' سکه')+' به همه هدیه داد')}save();return c.send({t:'info',e:'برای همه ارسال شد ✅'})}
 if(m.t==='banlist')return c.send({t:'banlist',list:Object.entries(DB.bans).filter(e=>e[1]>Date.now()).map(e=>({n:e[0],until:e[1],vip:!!DB.vip[e[0]]}))});
 if(!t)return c.send({t:'err',e:'بازیکن پیدا نشد'});
 if(m.t==='coinsTo'||m.t==='gems'){const k=m.t==='gems'?'gems':'coins';t[k]+=Math.floor(+m.v)||0;note(m.n,'🎁 مدیر '+(Math.floor(+m.v)||0)+(k==='gems'?' جم':' سکه')+' به حساب تو اضافه کرد')}
 else if(m.t==='unban'){if(DB.vip[m.n])return c.send({t:'err',e:'بن VIP همیشگی است و قابل برداشتن نیست 👑'});delete DB.bans[m.n]}
 else if(DB.vip[m.n])return c.send({t:'err',e:'این کاربر بن VIP همیشگی است'});
 else{if(m.t==='vipban'){DB.vip[m.n]=1;if(t.ip&&t.ip!==c.ip)DB.vipIp[t.ip]=m.n}DB.bans[m.n]=Date.now()+(m.t==='vipban'?36500:Math.max(1,Math.min(36500,+m.days||1)))*864e5;const x=conns[m.n];if(x){x.send({t:'banned',vip:m.t==='vipban'?1:0});x.sock.end()}}
 save();c.send({t:'info',e:'انجام شد ✅'})}

/* ---------- موتور بازی ---------- */
function sendRole(r,n){const P=r.g.P,p=P.find(x=>x.n===n);if(p)to(n,{t:'role',r:p.r,p:P.map(x=>x.n),mates:isM(p)?P.filter(q=>q!==p&&isM(q)).map(q=>q.n):[]})}
function kill(r,p,why){if(!p.ok)return;p.ok=0;bc(r,{t:'dead',n:p.n,r:p.r,why});const g=r.g;if(g&&g.tk&&g.tk.n===p.n)g.tk.f()}
function start(r){const n=r.m.length;let rl;
 if(r.scRoles)rl=fitRoles(r.scRoles,n);else if(n===r.max)rl=SC[r.sc].slice();else{const mf=n>=9?3:n>=6?2:1;rl=['رئیس مافیا',...rep(M,mf-1),...SC[r.sc].filter(x=>!/مافیا/.test(x)).slice(0,n-mf)]}
 shuf(rl);const P=r.m.map((x,i)=>({n:x.n,r:rl[i],ok:1,k:KILLER[rl[i]]?1:0,sh:rl[i]==='نگهبان',b:rl[i]==='تفنگدار'?2:0,gun:0}));
 r.g={t0:Date.now(),P,d:0,x:0,night:0,w:null,tk:null};P.forEach(p=>sendRole(r,p.n));pushLobbies();
 setTimeout(()=>run(r).catch(e=>{if(e!==0)console.error(e)}),8000/TS)}
const wins=(p,w)=>w==='مافیا'?isM(p):w==='شهروندان'?(RT[p.r]==='c'||(p.r==='بازمانده'&&!!p.ok)):(p.r===w||(p.r==='بازمانده'&&!!p.ok));
function finish(r,w){const g=r.g;g.x=1;bc(r,{t:'end',w,wn:g.P.filter(p=>wins(p,w)).map(p=>p.n),roles:g.P.map(p=>({n:p.n,r:p.r,ok:p.ok}))});
 r.w=[];g.P.forEach(p=>{const u=DB.users[p.n],win=wins(p,w);if(!p.kicked)u.coins=Math.max(0,u.coins+(win?100:-100));u.games++;if(win)u.wins++;if(r.rk)DB.lg[p.n]=Math.max(0,(DB.lg[p.n]||0)+(win?10:-5));to(p.n,{t:'bal',coins:u.coins,gems:u.gems})});
 if(r.lid&&DB.lregs[r.lid])DB.lregs[r.lid].hrs+=(Date.now()-g.t0)/36e5*TS;save();r.g=null;r.m=r.m.filter(x=>where[x.n]===r.id);r.m.forEach(x=>x.rd=0);
 if(!r.m.length){if(!r.lid)delete R[r.id]}else setTimeout(()=>{if(R[r.id]){pushRoom(r)}pushLobbies()},600)}
async function run(r){const g=r.g,P=g.P,al=()=>P.filter(p=>p.ok),pn=n=>P.find(p=>p.n===n);
 const chk=()=>{if(g.x||R[r.id]!==r)throw 0};
 const over=()=>{if(g.jw)return 'دلقک';const a=al(),m=a.filter(isM).length,k=a.filter(p=>p.k);if(k.length&&a.length<=2)return k[0].r;if(m===0&&!k.length)return 'شهروندان';return m>0&&m>=a.length-m?'مافیا':0};
 const say=async t=>{while(g.paused&&!g.x)await sleep(300);chk();bc(r,{t:'say',text:t});await sleep(900+t.length*50);chk()};
 const turn=(p,sec)=>new Promise(f=>{const t={n:p.n,f:()=>{clearTimeout(t.tm);g.tk=null;f()}};t.tm=setTimeout(t.f,sec*1000/TS);g.tk=t;bc(r,{t:'turn',n:p.n,sec})});
 const ask=(ph,who,text,sec,ok)=>new Promise(f=>{const w={who:who.map(p=>p.n),got:{},ok},tm=setTimeout(()=>w.fin(),(sec+1)*1000/TS);w.fin=()=>{clearTimeout(tm);g.w=null;f(w.got)};g.w=w;who.forEach(p=>to(p.n,{t:'phase',ph,who:[p.n],text,sec}));if(!who.length)w.fin()});
 const has=x=>P.some(p=>p.r===x),alv=x=>al().filter(p=>p.r===x);
 const night=async(role,who,line,text,ok)=>{await say(line);if(!who.length){await sleep(2500+Math.random()*3000);return{}}const got=await ask('nt',who,text,12,ok);chk();return got};
 const vote=async c=>{const got=await ask('vote',al(),'رأی تو؟ روی بازیکن بزن',12,(a,t)=>a!==t&&c.includes(t)),v={};chk();Object.entries(got).forEach(([a,n])=>{v[n]=(v[n]||0)+(pn(a)&&pn(a).r==='شهردار'?2:1)});
  const ids=Object.keys(v),mx=Math.max(0,...ids.map(i=>v[i]));if(ids.length)await say('نتیجه رأی: '+ids.map(i=>i+' '+v[i]).join(' | '));return{v,top:ids.filter(i=>v[i]===mx&&mx>0)}};
 const revenge=async(p,why)=>{if(!(p.r==='شکارچی'||(p.r==='تروریست مافیا'&&why==='رأی')))return null;await say((p.r==='شکارچی'?'شکارچی':'تروریست')+' آخرین شلیکش را انتخاب می‌کند');const got=await ask('nt',[p],'آخرین شلیکت را به چه کسی می‌زنی؟',12,(a,t)=>a!==t);chk();const t=Object.values(got)[0];return t?pn(t):null};
 let w;
 while(!(w=over())){
  g.d++;await say('روز '+g.d+' شروع شد. وقت بحث است');
  for(const p of al()){if(!p.ok)continue;if(over())break;await say('نوبت '+p.n);if(!p.ok)continue;await turn(p,30);chk();await say('ممنونم، نفر بعد')}
  if(w=over())break;await say('خب، بریم برای رأی‌گیری');
  const r1=await vote(al()),ds=r1.top.filter(n=>r1.v[n]>=Math.ceil(al().length/3));
  if(ds.length){for(const n of ds){await say('دفاعیه '+n);await turn(pn(n),30);chk()}
   await say('رأی‌گیری مجدد');const r2=await vote(ds.map(pn));
   const e=r2.top.length===1&&r2.v[r2.top[0]]>=Math.ceil(al().length/2)?pn(r2.top[0]):null;
   if(e){await say(e.n+' حذف شد. وصیت');await turn(e,30);chk();const rv=await revenge(e,'رأی');kill(r,e,'رأی');if(rv)kill(r,rv,'انتقام');await say('نقش '+e.n+': '+e.r+(rv?' | '+rv.n+' ('+rv.r+') هم با او حذف شد':''));if(e.r==='دلقک')g.jw=1;if(w=over())break}
   else await say('کسی حذف نشد. بریم برای شب')}
  else await say('رأی کافی نبود. بریم برای شب');
  g.night=1;await say('شب شد. همه چشم‌ها را ببندند');
  const nm=al().filter(p=>!isM(p)),boss=P.find(p=>p.r==='رئیس مافیا'&&p.ok);
  let got=await night('م',al().filter(isM),'مافیا بیدار شود. یار خودت را ببین. امشب کی رو می‌خوای از بین ببری؟','هدف شب را انتخاب کن',(a,t)=>!isM(t));
  const tg=(boss&&got[boss.n])||Object.values(got).pop()||rnd(nm).n;const kts=[],jls=new Set(),blk=new Set(),frm=new Set(),svs=new Set(),gds=[],csl=[],dz=g.dz=g.dz||new Set(),extra=[];
  const ents=g2=>Object.entries(g2).filter(e=>!blk.has(e[0]));
  if(has('زندانبان')){got=await night('ز',alv('زندانبان'),'زندانبان بیدار شود. چه کسی را امشب زندانی می‌کنی؟','چه کسی را زندانی می‌کنی؟',(a,t)=>a!==t);Object.entries(got).forEach(q=>{jls.add(q[1]);blk.add(q[1])})}
  if(has('هکر مافیا')){got=await night('ه',alv('هکر مافیا'),'هکر بیدار شود. توانایی چه کسی را امشب قطع می‌کنی؟','توانایی چه کسی را قطع می‌کنی؟',(a,t)=>!isM(t));ents(got).forEach(q=>blk.add(q[1]))}
  if(has('فریبکار مافیا')){got=await night('ف',alv('فریبکار مافیا'),'فریبکار بیدار شود. چه کسی را در استعلام مافیا نشان می‌دهی؟','چه کسی را مشکوک جلوه بدهم؟',(a,t)=>!isM(t));ents(got).forEach(q=>frm.add(q[1]))}
  if(has('دکتر')){got=await night('د',alv('دکتر'),'دکتر بیدار شود. چه کسی را نجات می‌دهی؟','نجات چه کسی؟',()=>1);ents(got).forEach(q=>svs.add(q[1]))}
  if(has('بادیگارد')){got=await night('ب',alv('بادیگارد'),'بادیگارد بیدار شود. از چه کسی محافظت می‌کنی؟','از چه کسی محافظت می‌کنی؟',(a,t)=>a!==t);ents(got).forEach(q=>gds.push(q))}
  for(const rn of ['کارآگاه','بازپرس']){if(!has(rn))continue;got=await night('ک',alv(rn),rn+' بیدار شود. استعلام چه کسی؟','استعلام چه کسی؟',(a,t)=>a!==t);ents(got).forEach(q=>{const t=pn(q[1]),ind=RT[t.r]==='i'&&!frm.has(t.n);to(q[0],Object.assign({t:'detect',n:t.n,mafia:(isM(t)&&t.r!=='رئیس مافیا')||frm.has(t.n)},rn==='بازپرس'&&ind?{txt:t.n+' مستقل است (نه مافیا، نه شهروند)'}:{}))})}
  if(has('تکاور')){got=await night('ت',alv('تکاور'),'تکاور بیدار شود. آیا کسی را هدف می‌گیری؟','هدف تکاور؟ (رد کردن = شلیک نمی‌کنی)',(a,t)=>a!==t);ents(got).forEach(q=>csl.push(q))}
  if(P.some(p=>p.r==='تفنگدار'&&p.b>0)){const gn=alv('تفنگدار').filter(p=>p.b>0);got=await night('ف',gn,'تفنگدار بیدار شود. تفنگ را به چه کسی می‌دهی؟','تفنگ را به چه کسی می‌دهی؟',(a,t)=>a!==t);ents(got).forEach(q=>{const t=pn(q[1]);t.gun=1;pn(q[0]).b--;to(t.n,{t:'gun'})})}
  if(has('قاتل زنجیره‌ای')){got=await night('ق',alv('قاتل زنجیره‌ای'),'قاتل زنجیره‌ای بیدار شود. قربانی امشب؟','قربانی امشب؟',(a,t)=>a!==t);ents(got).forEach(q=>kts.push(q[1]))}
  if(has('آتش‌افروز')){got=await night('آ',alv('آتش‌افروز'),'آتش‌افروز بیدار شود. یک نفر را بنزین بریز، یا خودت را انتخاب کن تا همه‌ی بنزین‌خورده‌ها بسوزند.','هدف را انتخاب کن (خودت = آتش زدن)',()=>1);ents(got).forEach(q=>{if(q[1]===q[0]){dz.forEach(n=>{const x=pn(n);if(x&&x.ok&&!extra.includes(x))extra.push(x)});dz.clear()}else dz.add(q[1])})}
  if(has('نگهبان')){await say('نگهبان بیدار شود و دوباره بخوابد');await sleep(2500+Math.random()*2500);chk()}
  blk.forEach(n=>{const x=pn(n);if(x&&x.ok&&NIGHTR[x.r])to(n,{t:'info',e:'🔒 امشب توانایی تو قطع شد'})});
  const ks=[],hit=(id,bypass)=>{let v=pn(id);if(!v||!v.ok||jls.has(v.n))return;if(!bypass&&svs.has(v.n))return;const gq=gds.find(q=>q[1]===v.n&&q[0]!==v.n&&pn(q[0])&&pn(q[0]).ok);if(gq)v=pn(gq[0]);if(v.sh){v.sh=0;return}ks.push(v)};
  hit(tg);kts.forEach(x=>hit(x));extra.forEach(x=>hit(x.n,1));
  csl.forEach(q=>{const c=pn(q[1]);if(!c||jls.has(c.n))return;ks.push((isM(c)||c.k)?c:pn(q[0]))});
  const dead=[...new Set(ks)].filter(p=>p&&p.ok);g.night=0;
  for(const p of [...dead]){if(p.r==='شکارچی'){const rv=await revenge(p,'شب');if(rv&&rv.ok&&!dead.includes(rv))dead.push(rv)}}
  await say('صبح می‌شود. '+(dead.length?dead.map(p=>p.n+' ('+p.r+')').join(' و ')+' کشته شد':'کسی کشته نشد'));dead.forEach(p=>kill(r,p,'شب'));
  const gunner=P.find(p=>p.ok&&p.gun&&conns[p.n]);if(gunner)to(gunner.n,{t:'gun'})}
 await sleep(1500);chk();finish(r,w)}


/* لابی‌های تیک‌دار بعد از ری‌استارت سرور دوباره ساخته می‌شوند (خالی، با همان تیک و ساعت‌ها) */
function restoreTicks(){try{Object.values(DB.lregs||{}).forEach(l=>{if(!l||l.st!=='ok'||!(l.made||l.hrs>0))return;if(Object.values(R).some(x=>x.lid===l.id))return;const sc=SC[l.sc]?l.sc:'تکاور';const rr=mkRoom(l.name,sc,l.owner,0);rr.lid=l.id;if(sc==='اختصاصی'&&Array.isArray(l.scr)&&!scCheck(l.scr)){rr.scRoles=l.scr.slice();rr.scn=l.scn||'سناریو';rr.max=rr.scRoles.length}})}catch(e){console.error('restoreTicks',e)}}
restoreTicks();
server.listen(PORT,()=>console.log('Mafia server on :'+PORT+(PAGE?' (serving game html)':' (no html found next to server.js)')));
