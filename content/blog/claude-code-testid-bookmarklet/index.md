+++
title = "Claude Code 한테 '그 버튼 말야' 라고 못 하잖아"
date = 2026-05-27
draft = false
tags = ["claude-code", "frontend", "tooling", "workflow"]
+++

프론트 작업을 Claude Code 한테 시킬 때 매번 부딪히는 게 이거다.

"메인 페이지에서 검색 버튼 옆에 있는 그 작은 X 버튼 말야, 색 좀 바꿔줘" — 이렇게 말하면 Claude는 어느 파일의 어느 컴포넌트인지 모른다. 결국 내가 찾아주거나, 한참 헤매다가 엉뚱한 데 손대거나, 둘 중 하나.

이거 매번 반복되니까 시간 깎이는 게 아까워서 셋업을 좀 정리했다. 별거 아닌데 효과는 꽤 컸음.

## 일단 data-testid 컨벤션부터

방법 자체는 단순하다. 컴포넌트마다 `data-testid="..."` 를 박아두고, Claude한테 그 testid로 지시하면 된다.

```html
<button data-testid="search-clear-btn">×</button>
```

이러면 채팅에서

> "`data-testid="search-clear-btn"` 이거 너무 크니까 작게 줄여줘"

이 한 줄로 끝난다. 위치 설명할 필요 없고, 셀렉터 헷갈릴 일 없고, Claude도 한 번에 찾는다. 어차피 e2e 테스트 쪽에서 원래 testid 쓰니까 일석이조다.

## 근데 컴포넌트 100개면 testid도 100개

testid 박는 건 좋은데 — 컴포넌트가 늘어나면 어디에 뭐 박혔는지 결국 까먹는다. 다시 코드 뒤지러 가야 함. 그럼 처음 문제로 돌아간다. ("어디에 뭐 있더라" → 코드 검색 → 시간 깎임)

내가 원하는 건: 브라우저에서 그 컴포넌트를 보고 있는 상태에서, 마우스로 가리키면 testid가 바로 튀어나오는 것.

## 그래서 만든 게 이 북마클릿

화면 보면서 마우스로 컴포넌트 호버하면 testid가 위에 뜨고, 클릭하면 `data-testid="..."` 가 클립보드에 복사된다. ESC로 종료.

```javascript
javascript:(function(){if(window.__tidActive&&window.__tidStop){window.__tidStop();return}window.__tidActive=true;var ov=document.createElement('div');Object.assign(ov.style,{position:'fixed',pointerEvents:'none',zIndex:'2147483647',border:'2px dashed #1a73e8',background:'rgba(26,115,232,0.15)',boxSizing:'border-box',transition:'all 0.05s ease'});document.body.appendChild(ov);var tip=document.createElement('div');Object.assign(tip.style,{position:'fixed',zIndex:'2147483647',background:'#1a1a2e',color:'#fff',padding:'4px 8px',borderRadius:'4px',fontSize:'11px',fontFamily:'monospace',pointerEvents:'none',whiteSpace:'nowrap',boxShadow:'0 4px 12px rgba(0,0,0,0.5)'});document.body.appendChild(tip);var cur=null;function findTid(el){while(el&&el!==document.documentElement){if(el.getAttribute&&el.getAttribute('data-testid'))return el;el=el.parentElement}return null}function onMove(e){var el=e.target,found=findTid(el);cur=found||el;var r=cur.getBoundingClientRect();ov.style.top=r.top+'px';ov.style.left=r.left+'px';ov.style.width=r.width+'px';ov.style.height=r.height+'px';var tid=cur.getAttribute('data-testid');tip.textContent=tid?'ID: '+tid:'(data-testid 없음)';tip.style.background=tid?'#1a73e8':'#444';var tx=r.left,ty=r.top-24;if(ty<5)ty=r.bottom+5;if(tx+tip.offsetWidth>window.innerWidth)tx=window.innerWidth-tip.offsetWidth-5;tip.style.left=tx+'px';tip.style.top=ty+'px'}function copyText(s){try{var ta=document.createElement('textarea');ta.value=s;ta.style.position='fixed';ta.style.opacity='0';document.body.appendChild(ta);ta.focus();ta.select();var ok=document.execCommand('copy');document.body.removeChild(ta);return ok}catch(e){return false}}function onClick(e){e.preventDefault();e.stopPropagation();var tid=cur&&cur.getAttribute('data-testid');var stopNow=function(){try{window.__tidStop&&window.__tidStop()}catch(e){}};if(!tid){showToast('❌ data-testid 없음');stopNow();return}var s='data-testid="'+tid+'"';var done=function(ok){showToast((ok?'✓ 복사됨: ':'⚠ 복사실패(수동복사): ')+s);stopNow()};if(navigator.clipboard&&window.isSecureContext){navigator.clipboard.writeText(s).then(function(){done(true)},function(){done(copyText(s))})}else{done(copyText(s))}}function onKey(e){if(e.key==='Escape')window.__tidStop()}function showToast(msg){var toast=document.createElement('div');toast.textContent=msg;Object.assign(toast.style,{position:'fixed',bottom:'20px',left:'50%',transform:'translateX(-50%)',background:'#059669',color:'#fff',padding:'10px 20px',borderRadius:'8px',fontSize:'13px',fontFamily:'monospace',zIndex:'2147483647',pointerEvents:'auto',userSelect:'text',maxWidth:'80vw',wordBreak:'break-all'});document.body.appendChild(toast);setTimeout(function(){toast.remove()},4000)}window.__tidStop=function(){document.removeEventListener('mouseover',onMove,true);document.removeEventListener('click',onClick,true);document.removeEventListener('keydown',onKey,true);ov.remove();tip.remove();window.__tidActive=false;window.__tidStop=null};document.addEventListener('mouseover',onMove,true);document.addEventListener('click',onClick,true);document.addEventListener('keydown',onKey,true);showToast('🚀 TestID Picker ON')})();
```

설치는 단순하다. 브라우저 북마크 새로 만들고, URL 칸에 위 코드를 통째로(앞의 `javascript:` 포함해서) 붙여넣고, 이름은 적당히 "TestID Picker" 정도로.

![브라우저 북마크 추가 화면 — URL 칸에 javascript:(function(){...}) 통째로 붙여넣은 모습](01-bookmark-edit.png)

쓰는 흐름:

1. 작업하려는 페이지 띄워둔 상태에서 그 북마크 클릭
2. "🚀 TestID Picker ON" 토스트가 뜸
3. 마우스 따라 파란 점선 박스가 움직이고, testid 있는 요소엔 박스 위에 ID 표시
4. 컴포넌트 클릭 → `data-testid="..."` 가 클립보드에 자동 복사
5. ESC로 종료. 채팅에 붙여넣고 지시

호버할 때 가장 가까운 `data-testid` 가진 부모를 찾아주니까, 안쪽 텍스트나 아이콘을 정확히 안 찍어도 됨.

![북마클릿 동작 — 사이트 로고에 호버하니 파란 점선 박스와 함께 "ID: navbar-logo" 가 표시되는 모습](02-picker-hover.png)

## 셋업 시 컨벤션 한 줄

이게 효과 보려면 testid가 미리 박혀 있어야 한다. 후행으로 박는 건 귀찮으니까 프로젝트 처음부터:

- **인터랙티브 요소**(버튼, 폼 인풋, 링크): 무조건 testid
- **명명 규칙**: `영역-역할` (예: `navbar-search`, `cart-checkout-btn`)
- **컨테이너/카드**: 의미 있는 것만. 너무 많이 박으면 노이즈

shadcn/ui 같은 라이브러리 컴포넌트는 컴포넌트 자체에 못 박는 경우가 있다. 그럴 땐 wrapper div 한 겹 두고 거기 단다.

## 정적 사이트는 런타임 주입으로 우회

지금 이 블로그(Hugo + Hextra 테마)처럼 빌드 결과물에 testid 박기 어려운 경우엔 런타임 JS로 자동 부여하는 방법도 있다. body 끝(또는 head 끝)에 작은 스크립트 박아두고, DOMContentLoaded에서 셀렉터 매핑으로 testid를 붙인다.

이 블로그도 그렇게 했다. `layouts/_partials/custom/head-end.html` 에 스크립트 한 토막 박아둔 게 전부. 페이지 열리면 알아서 `navbar`, `sidebar`, `footer`, `post-title`, `heading-h2-...` 같은 testid가 붙는다. 그래서 이 글 페이지에서 그대로 위 북마클릿 돌려보면 바로 작동한다.

## 결론

엄청 새로운 발상은 아니다. testid는 e2e 테스트에서 원래 쓰던 거고, 북마클릿도 형식만 다를 뿐 흔한 헬퍼다.

근데 Claude Code랑 페어 코딩한다는 맥락에서 보면 — "어디"를 0.5초에 끝낼 수 있다는 게 누적되면 진짜 크다. 새 프로젝트 시작하면 README에 testid 컨벤션 한 줄 적어두고, 북마클릿은 북마크 바에 박아두는 정도가 좋은 디폴트인 듯.
