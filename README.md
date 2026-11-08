# 인생은 펠리컨처럼!

개인 블로그 — 개발 기록, 기술 메모, 잡상, 사적인 글. 장르 안 가림.

- 배포 URL: https://poorants.github.io/
- 빌드·배포: `main` 푸시 → GitHub Actions → Pages
- 테마: [Hextra](https://github.com/imfing/hextra) (submodule, `themes/hextra`)

## 글 추가

```
hugo new content content/blog/my-post.md
```

또는 `content/blog/` 아래에 직접 마크다운 파일을 추가한다. 프론트매터의 `draft = true` 면 발행되지 않는다.

## 로컬 미리보기

```
hugo server -D
```

## 배포

`main` 브랜치에 푸시하면 `.github/workflows/hugo.yml` 이 자동으로 빌드·배포한다.

## Link previews, SEO and link checks

- Each post gets a 1200x630 social preview image generated at build time from its title
  (`layouts/_partials/custom/og-image.html`, background `assets/og/background.png`,
  font `assets/fonts/Pretendard-Bold.ttf`, SIL OFL 1.1). To use your own image, put
  `cover.*` or `featured.*` in the post bundle, or set `images = ["..."]` in front matter.
- `description` in front matter feeds the meta description, og:description and JSON-LD;
  when empty, the first paragraph is used.
- `.github/workflows/links.yml` checks links on every PR and push to main with lychee:
  internal links block, external links are reported only. Skip flaky hosts in `.lycheeignore`.
