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
