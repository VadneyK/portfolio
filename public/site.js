// Subtle motion: sections rise in once as they scroll into view, and the nav marks the section you are reading.
(function () {
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var sections = Array.prototype.slice.call(document.querySelectorAll("main > section[id]"));
  var links = {};
  Array.prototype.forEach.call(document.querySelectorAll(".top nav a"), function (a) {
    links[a.getAttribute("href").slice(1)] = a;
  });
  if (!("IntersectionObserver" in window)) return;
  if (!reduce) {
    document.documentElement.classList.add("motion");
    var rise = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("in"); rise.unobserve(e.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px" });
    sections.forEach(function (s) { rise.observe(s); });
  }
  var spy = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      var a = links[e.target.id];
      if (!a) return;
      if (e.isIntersecting) {
        Object.keys(links).forEach(function (k) { links[k].removeAttribute("aria-current"); });
        a.setAttribute("aria-current", "true");
      }
    });
  }, { rootMargin: "-45% 0px -50% 0px" });
  sections.forEach(function (s) { spy.observe(s); });
})();
