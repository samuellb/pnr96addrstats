---
layout: page
title: About
permalink: /about/
---
{% capture index_content %}{% include index.md %}{% endcapture %}
{{ index_content | markdownify }}
