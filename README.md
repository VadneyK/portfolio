# portfolio

Kentaro Vadney's projects and work: live demos, agent tools, hardware and 3D printing, writing, and work history.
A static page in `public/`, served by GitHub Pages at https://vadneyk.github.io/portfolio/ once the repo is public.

Every line on the page comes from a project's own README or from the resume. Do not add a claim that is not in one of
those, and do not add contact details beyond the GitHub and LinkedIn links.

## Check and release

```bash
make check   # static checks + layout-check at nine widths (320 to 2560) against a local server
make ship    # check, merge the open PR, wait for Pages to serve that commit, smoke-test live, revert on failure
```

`make ship` is the only way to release. Never merge or push to `main` by hand.

`tests/check_static.py` fails on dashes, phone numbers, email addresses, abandoned or private project names, links to
company repos, broken local links and anchors, and images without alt text. `tests/layout-check.mjs` is a copy of the
layout-check skill script; keep it in sync when the skill changes.

## Screenshots

`public/img/*.jpg` are 1280 by 800 captures of each live demo, scaled to 800 wide. Refresh them with headless Chrome
when a demo changes.
