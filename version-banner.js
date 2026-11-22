/* SAIG report versioning: version switcher and "superseded" banner.

   Served once at /ai-emissions/version-banner.js and loaded by every version
   of the report, including frozen archives. Reads /ai-emissions/versions.json,
   so a new release only needs versions.json updated; archived pages are never
   edited again.

   Fails silently: if versions.json cannot be loaded, the page is unchanged. */

(() => {
  const BASE = "/ai-emissions/";
  const REGISTRY = BASE + "versions.json";

  const css = `
    .saig-version-banner {
      position: relative; z-index: 1050;
      display: flex; flex-wrap: wrap; align-items: center; justify-content: center;
      gap: .35rem 1rem; padding: .7rem 1rem;
      background: #033845; color: #F5F1E9;
      font-family: "DM Mono", monospace; font-size: .78rem; letter-spacing: .02em;
      box-shadow: 0 2px 10px rgba(0,0,0,.15);
    }
    .saig-version-banner strong { color: #F2A74C; font-weight: 500; }
    .saig-version-banner a {
      color: #033845 !important; background: #F5F1E9; text-decoration: none !important;
      padding: .25rem .65rem; border-radius: 999px; white-space: nowrap;
    }
    .saig-version-banner a:hover { background: #F2A74C; }
    .saig-version-tag {
      display: inline-block; margin-left: .5rem; padding: .05rem .45rem;
      border-radius: 999px; font-size: .62rem; letter-spacing: .08em; vertical-align: middle;
      background: #E6ECED; color: #2B6572;
    }
    .saig-version-tag.is-superseded { background: #EED4B9; color: #B8663B; }
    .saig-version-switch { position: relative; display: inline-block; margin-top: .45rem; }
    .saig-version-switch summary {
      list-style: none; cursor: pointer; font-family: "DM Mono", monospace;
      font-size: .7rem; letter-spacing: .04em; color: #2B6572;
    }
    .saig-version-switch summary::-webkit-details-marker { display: none; }
    .saig-version-switch[open] summary { color: #B8663B; }
    .saig-version-menu {
      margin-top: .45rem; min-width: 19rem; max-width: 100%;
      background: #F5F1E9; border-radius: 10px;
      padding: .4rem; font-family: "DM Mono", monospace; font-size: .74rem;
    }
    .saig-version-menu a {
      display: flex; justify-content: space-between; gap: 1rem;
      padding: .45rem .6rem; border-radius: 6px;
      color: #033845 !important; text-decoration: none !important;
    }
    .saig-version-menu a { white-space: nowrap; }
    .saig-version-menu a:hover, .saig-version-menu a[aria-current="page"] { background: #fff; }
    .saig-version-menu span { color: #4F747D; }
    .saig-version-doi {
      display: block; margin-top: .3rem; font-family: "DM Mono", monospace;
      font-size: .7rem; letter-spacing: .02em; color: #2B6572 !important;
      text-decoration: none !important;
    }
    .saig-version-doi:hover { text-decoration: underline !important; }
    @media print { .saig-version-banner, .saig-version-switch { display: none !important; } }
  `;

  const fmtDate = (iso) => {
    try {
      return new Date(iso + "T00:00:00Z").toLocaleDateString("en-US", {
        day: "numeric", month: "long", year: "numeric", timeZone: "UTC"
      });
    } catch (e) {
      return iso;
    }
  };

  // Which version is this page? /ai-emissions/<code>/ is a pinned version;
  // the bare /ai-emissions/ path is always the latest.
  const pageCode = (registry) => {
    const rest = location.pathname.startsWith(BASE)
      ? location.pathname.slice(BASE.length).split("/")[0]
      : "";
    const match = registry.versions.find((v) => v.code === rest);
    return match ? match.code : registry.latest;
  };

  const addBanner = (registry, current, latest) => {
    if (current.code === latest.code || document.querySelector(".saig-version-banner")) return;
    const bar = document.createElement("div");
    bar.className = "saig-version-banner";
    bar.setAttribute("role", "note");
    bar.innerHTML = `
      <span>You are viewing <strong>${current.id}</strong>, published ${fmtDate(current.date)}.
      It has been superseded by ${latest.id} (${fmtDate(latest.date)}).</span>
      <a href="${latest.url}">View latest version →</a>
      ${latest.changelog ? `<a href="${latest.changelog}">What changed</a>` : ""}
    `;
    document.body.prepend(bar);
  };

  const addSwitcher = (registry, current, latest) => {
    const labels = [...document.querySelectorAll(".saig-meta-label")];
    const label = labels.find((el) => el.textContent.trim().toUpperCase() === "VERSION");
    if (!label || label.parentElement.querySelector(".saig-version-switch")) return;

    const tag = document.createElement("span");
    const isLatest = current.code === latest.code;
    tag.className = "saig-version-tag" + (isLatest ? "" : " is-superseded");
    tag.textContent = isLatest ? "LATEST" : "SUPERSEDED";
    label.appendChild(tag);

    const items = [...registry.versions]
      .sort((a, b) => (a.date < b.date ? 1 : -1))
      .map((v) => `
        <a href="${v.url}" ${v.code === current.code ? 'aria-current="page"' : ""}>
          ${v.id}<span>${fmtDate(v.date)}${v.code === latest.code ? " · latest" : ""}</span>
        </a>`)
      .join("");

    const switcher = document.createElement("details");
    switcher.className = "saig-version-switch";
    switcher.innerHTML = `
      <summary>All versions (${registry.versions.length}) ▾</summary>
      <div class="saig-version-menu">${items}</div>
    `;
    label.parentElement.appendChild(switcher);
  };

  // Add the version's DOI (from versions.json) to the citation panel and the
  // VERSION card. DOIs are minted after a version is frozen, so they are
  // supplied here rather than written into archived pages.
  const addDoi = (current) => {
    if (!current.doi) return;
    const url = "https://doi.org/" + current.doi;

    const cite = document.querySelector(".saig-cite-panel p");
    if (cite && !cite.querySelector(".saig-doi")) {
      const a = document.createElement("a");
      a.className = "saig-doi";
      a.href = url;
      a.textContent = url;
      cite.appendChild(document.createTextNode(" "));
      cite.appendChild(a);
    }

    const bib = document.getElementById("saig-bibtex");
    if (bib && !/\bdoi\s*=/.test(bib.textContent)) {
      bib.textContent = bib.textContent.replace(
        /(\n\s*url\s*=)/,
        "\n    doi          = {" + current.doi + "},$1"
      );
    }

    const labels = [...document.querySelectorAll(".saig-meta-label")];
    const label = labels.find((el) => el.textContent.trim().toUpperCase().startsWith("VERSION"));
    if (label && !label.parentElement.querySelector(".saig-version-doi")) {
      const d = document.createElement("a");
      d.className = "saig-version-doi";
      d.href = url;
      d.textContent = "DOI " + current.doi;
      const value = label.parentElement.querySelector(".saig-meta-value");
      (value || label).insertAdjacentElement("afterend", d);
    }
  };

  const run = async () => {
    let registry;
    try {
      const res = await fetch(REGISTRY, { cache: "no-cache" });
      if (!res.ok) return;
      registry = await res.json();
    } catch (e) {
      return;
    }
    const byCode = (c) => registry.versions.find((v) => v.code === c);
    const latest = byCode(registry.latest);
    const current = byCode(pageCode(registry));
    if (!latest || !current) return;

    const style = document.createElement("style");
    style.textContent = css;
    document.head.appendChild(style);

    addBanner(registry, current, latest);
    addSwitcher(registry, current, latest);
    addDoi(current);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", run);
  } else {
    run();
  }
})();
