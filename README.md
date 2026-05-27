# poorants.github.io

개인 개발 블로그 (Hugo + GitHub Pages).

- 배포 URL: https://poorants.github.io/
- 빌드·배포: `main` 푸시 → GitHub Actions → Pages
- 테마: [PaperMod](https://github.com/adityatelange/hugo-PaperMod) (submodule, `themes/PaperMod`)

## 글 추가

```
hugo new content content/posts/my-post.md
```

또는 `content/posts/` 아래에 직접 마크다운 파일을 추가한다. 프론트매터의 `draft = true` 면 발행되지 않는다.

## 로컬 미리보기

```
hugo server -D
```

## 배포

`main` 브랜치에 푸시하면 `.github/workflows/hugo.yml` 이 자동으로 빌드·배포한다.
