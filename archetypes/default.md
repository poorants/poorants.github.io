+++
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
date = {{ .Date }}
draft = true
# One or two sentences for search results and link previews (meta description, og:description).
# Leave empty to fall back to the first paragraph.
description = ""
tags = []
categories = []
# Social preview image: a 1200x630 card is generated from the title at build time.
# To override, put cover.png (or featured.jpg, ...) in the page bundle, or set
# images = ["my-image.png"]  # page resource name, site path, or absolute URL
+++
