(function () {
  var DEFAULT_BACKGROUND_COLOR = "#ffffff";
  var DEFAULT_TEXT_COLOR = "#111827";
  var DEFAULT_HIGHLIGHT_COLOR = "#2563eb";
  var DEFAULT_BORDER_COLOR = "#e5e7eb";
  var DEFAULT_BORDER_TYPE = "solid";
  var DEFAULT_BORDER_RADIUS = 8;
  var DEFAULT_WIDTH_RATIO = 15;
  var DEFAULT_HEIGHT_RATIO = 50;
  var DEFAULT_VERTICAL_START = 30;

  function parseConfig() {
    var configNode = document.querySelector("script[data-jtoc-config]");
    if (!configNode) {
      return {};
    }

    try {
      return JSON.parse(configNode.textContent || "{}");
    } catch (_error) {
      return {};
    }
  }

  function normalizeHexColor(value, fallback) {
    if (typeof value !== "string") {
      return fallback;
    }
    var raw = value.trim();
    if (!/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(raw)) {
      return fallback;
    }
    if (raw.length === 4) {
      return (
        "#" +
        raw.charAt(1) +
        raw.charAt(1) +
        raw.charAt(2) +
        raw.charAt(2) +
        raw.charAt(3) +
        raw.charAt(3)
      ).toLowerCase();
    }
    return raw.toLowerCase();
  }

  function getDirectChildList(item) {
    return item.querySelector(":scope > .jtoc-list");
  }

  function getDirectToggle(item) {
    return item.querySelector(":scope > .jtoc-link-row > .jtoc-fold-toggle");
  }

  function getTocScrollContainer(root) {
    return root.querySelector(".jtoc-nav");
  }

  function normalizeBoolean(value, fallback) {
    if (value === true || value === false) {
      return value;
    }
    if (typeof value === "string") {
      if (/^(true|1|yes|on)$/i.test(value)) {
        return true;
      }
      if (/^(false|0|no|off)$/i.test(value)) {
        return false;
      }
    }
    return fallback;
  }

  function normalizeInteger(value, fallback, min, max) {
    var parsed = Number(value);
    if (!Number.isFinite(parsed)) {
      return fallback;
    }
    var rounded = Math.round(parsed);
    if (rounded < min) {
      return min;
    }
    if (rounded > max) {
      return max;
    }
    return rounded;
  }

  function normalizeBorderType(value, fallback) {
    if (value === "solid" || value === "none" || value === "dot" || value === "dotted") {
      return value;
    }
    return fallback;
  }

  function resolveCssBorderType(value) {
    if (value === "dot") {
      return "dotted";
    }
    if (value === "none") {
      return "none";
    }
    return "solid";
  }

  function hasCssOverride(root, propertyName, defaultValue) {
    var previousInline = root.style.getPropertyValue(propertyName);
    if (previousInline) {
      root.style.removeProperty(propertyName);
    }
    var cssValue = window.getComputedStyle(root).getPropertyValue(propertyName).trim();
    if (previousInline) {
      root.style.setProperty(propertyName, previousInline);
    }
    if (!cssValue) {
      return false;
    }
    return cssValue.toLowerCase() !== String(defaultValue).trim().toLowerCase();
  }

  function setStyleByPriority(root, propertyName, defaultValue, configValue) {
    if (hasCssOverride(root, propertyName, defaultValue)) {
      root.style.removeProperty(propertyName);
      return;
    }
    root.style.setProperty(propertyName, configValue);
  }

  function resolveRuntimeStyle(config) {
    var scrollBehavior = config.scroll_behavior;
    if (!scrollBehavior || typeof scrollBehavior !== "object") {
      scrollBehavior = {};
    }
    var borderStyleConfig = config.border_style;
    if (!borderStyleConfig || typeof borderStyleConfig !== "object") {
      borderStyleConfig = {};
    }

    return {
      backgroundColor: normalizeHexColor(
        config.background_color,
        DEFAULT_BACKGROUND_COLOR
      ),
      textColor: normalizeHexColor(config.text_color, DEFAULT_TEXT_COLOR),
      highlightColor: normalizeHexColor(
        config.highlight_color,
        DEFAULT_HIGHLIGHT_COLOR
      ),
      borderColor: normalizeHexColor(borderStyleConfig.color, DEFAULT_BORDER_COLOR),
      borderType: normalizeBorderType(
        borderStyleConfig.type,
        DEFAULT_BORDER_TYPE
      ),
      borderRadius: normalizeInteger(borderStyleConfig.radius, DEFAULT_BORDER_RADIUS, 0, 999),
      hideAtBottom: normalizeBoolean(
        config.scroll_behavior !== undefined
          ? scrollBehavior.hide_at_bottom
          : config.hide_at_bottom,
        true
      ),
      hideAtTop: normalizeBoolean(
        config.scroll_behavior !== undefined
          ? scrollBehavior.hide_at_top
          : config.hide_at_top,
        false
      ),
      width: normalizeInteger(config.width, DEFAULT_WIDTH_RATIO, 8, 40),
      height: normalizeInteger(config.height, DEFAULT_HEIGHT_RATIO, 20, 90),
      verticalStart: normalizeInteger(
        config.vertical_start,
        DEFAULT_VERTICAL_START,
        0,
        100
      )
    };
  }

  function applyRuntimeStyle(root, runtimeStyle) {
    setStyleByPriority(root, "--jtoc-bg", DEFAULT_BACKGROUND_COLOR, runtimeStyle.backgroundColor);
    setStyleByPriority(root, "--jtoc-text", DEFAULT_TEXT_COLOR, runtimeStyle.textColor);
    setStyleByPriority(root, "--jtoc-highlight", DEFAULT_HIGHLIGHT_COLOR, runtimeStyle.highlightColor);
    setStyleByPriority(root, "--jtoc-border-color", DEFAULT_BORDER_COLOR, runtimeStyle.borderColor);
    setStyleByPriority(
      root,
      "--jtoc-border-style",
      DEFAULT_BORDER_TYPE,
      resolveCssBorderType(runtimeStyle.borderType)
    );
    setStyleByPriority(
      root,
      "--jtoc-radius",
      String(DEFAULT_BORDER_RADIUS) + "px",
      String(runtimeStyle.borderRadius) + "px"
    );
    setStyleByPriority(root, "--jtoc-width-ratio", String(DEFAULT_WIDTH_RATIO), String(runtimeStyle.width));
    setStyleByPriority(root, "--jtoc-height-ratio", String(DEFAULT_HEIGHT_RATIO), String(runtimeStyle.height));
    setStyleByPriority(
      root,
      "--jtoc-panel-vertical-start",
      String(DEFAULT_VERTICAL_START),
      String(runtimeStyle.verticalStart)
    );
    root.dataset.jtocHideAtBottom = runtimeStyle.hideAtBottom ? "true" : "false";
    root.dataset.jtocHideAtTop = runtimeStyle.hideAtTop ? "true" : "false";
  }

  function observeThemeChanges(root, runtimeStyle) {
    function reapply() {
      applyRuntimeStyle(root, runtimeStyle);
      updateEdgeSpacingByScrollbar(root);
      applyPanelMaxHeight(root);
    }

    var observer = new MutationObserver(function () {
      reapply();
    });

    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class", "data-theme", "style"]
    });

    if (document.body) {
      observer.observe(document.body, {
        attributes: true,
        attributeFilter: ["class", "data-theme", "style"]
      });
    }

    var darkMedia = window.matchMedia("(prefers-color-scheme: dark)");
    if (darkMedia && typeof darkMedia.addEventListener === "function") {
      darkMedia.addEventListener("change", reapply);
    } else if (darkMedia && typeof darkMedia.addListener === "function") {
      darkMedia.addListener(reapply);
    }
  }

  function updateEdgeSpacingByScrollbar(root) {
    var doc = document.documentElement;
    var body = document.body;
    var scrollHeight = Math.max(
      doc ? doc.scrollHeight : 0,
      body ? body.scrollHeight : 0
    );
    var viewportHeight = window.innerHeight || (doc ? doc.clientHeight : 0);
    var hasVerticalScrollbar = scrollHeight > viewportHeight + 1;
    var leftExtra = 0;
    var rightExtra = 0;

    if (hasVerticalScrollbar && doc) {
      var docRect = doc.getBoundingClientRect();
      var leftInset = Math.max(0, Math.round(docRect.left));
      var rightInset = Math.max(0, Math.round(window.innerWidth - docRect.right));
      var scrollbarOnLeft = leftInset > rightInset;
      if (scrollbarOnLeft) {
        rightExtra = 20;
      } else {
        leftExtra = 20;
      }
    }

    root.style.setProperty("--jtoc-edge-extra-left", leftExtra + "px");
    root.style.setProperty("--jtoc-edge-extra-right", rightExtra + "px");
  }

  function readCssCapMaxHeightPx(panel, root) {
    root.style.removeProperty("--jtoc-panel-max-height");
    var v = parseFloat(window.getComputedStyle(panel).maxHeight);
    if (!Number.isFinite(v) || v <= 0) {
      return null;
    }
    return v;
  }

  function captureInitialNavContentHeightOnce(root) {
    if (root.dataset.jtocInitialContentPx) {
      return;
    }
    var scrollEl = getTocScrollContainer(root);
    if (!scrollEl) {
      return;
    }
    var h = scrollEl.scrollHeight;
    if (h > 0) {
      root.dataset.jtocInitialContentPx = String(Math.ceil(h));
    }
  }

  function applyPanelMaxHeight(root) {
    var panel = root.querySelector(".jtoc-panel");
    var scrollEl = getTocScrollContainer(root);
    if (!panel || !scrollEl) {
      return;
    }

    if (window.matchMedia("(max-width: 900px)").matches) {
      root.style.removeProperty("--jtoc-panel-max-height");
      return;
    }

    var cssCap = readCssCapMaxHeightPx(panel, root);
    if (!cssCap) {
      return;
    }

    var initialContentPx = parseFloat(root.dataset.jtocInitialContentPx);
    var hasInitial = Number.isFinite(initialContentPx) && initialContentPx > 0;
    var fixedBase = hasInitial ? Math.min(initialContentPx, cssCap) : cssCap;

    root.style.setProperty("--jtoc-panel-max-height", fixedBase + "px");
  }

  function refreshFoldHeights(root) {
    var items = Array.prototype.slice.call(
      root.querySelectorAll(".jtoc-item.has-children")
    );

    items.reverse().forEach(function (item) {
      var childList = getDirectChildList(item);
      if (!childList) {
        return;
      }

      var toggle = getDirectToggle(item);
      var isOpen = item.classList.contains("is-open");
      if (toggle) {
        toggle.setAttribute("aria-expanded", String(isOpen));
      }

      if (!isOpen) {
        childList.style.maxHeight = "0px";
        return;
      }

      childList.style.maxHeight = "none";
      childList.style.maxHeight = childList.scrollHeight + "px";
    });

    captureInitialNavContentHeightOnce(root);
    applyPanelMaxHeight(root);
  }

  function setupMobileToggle(root) {
    var button = root.querySelector(".jtoc-mobile-toggle");
    if (!button) {
      return;
    }

    var backdrop = root.querySelector(".jtoc-mobile-backdrop");

    button.addEventListener("click", function () {
      var isOpen = root.classList.toggle("is-mobile-open");
      button.setAttribute("aria-expanded", String(isOpen));
    });

    if (backdrop) {
      backdrop.addEventListener("click", function () {
        root.classList.remove("is-mobile-open");
        button.setAttribute("aria-expanded", "false");
      });
    }
  }

  function getWindowScrollTop() {
    if (typeof window.scrollY === "number") {
      return window.scrollY;
    }
    if (typeof window.pageYOffset === "number") {
      return window.pageYOffset;
    }
    var docEl = document.documentElement;
    if (docEl && typeof docEl.scrollTop === "number") {
      return docEl.scrollTop;
    }
    if (document.body && typeof document.body.scrollTop === "number") {
      return document.body.scrollTop;
    }
    return 0;
  }

  function setupScrollEdgeVisibility(root) {
    function updateVisibility() {
      var scrollTop = getWindowScrollTop();
      var doc = document.documentElement;
      var body = document.body;
      var scrollHeight = Math.max(
        doc ? doc.scrollHeight : 0,
        body ? body.scrollHeight : 0
      );
      var viewportHeight = window.innerHeight || (doc ? doc.clientHeight : 0);
      var atTop = scrollTop <= 2;
      var atBottom = scrollTop + viewportHeight >= scrollHeight - 1;
      var scrollEdgeBehaviorActive = !window.matchMedia("(max-width: 900px)").matches;
      var hideAtBottom =
        scrollEdgeBehaviorActive && root.dataset.jtocHideAtBottom !== "false";
      var hideAtTop =
        scrollEdgeBehaviorActive && root.dataset.jtocHideAtTop === "true";
      var scrollHidden =
        (hideAtBottom && atBottom) || (hideAtTop && atTop);
      root.classList.toggle("is-scroll-hidden", scrollHidden);
      updateEdgeSpacingByScrollbar(root);
      applyPanelMaxHeight(root);
    }

    updateVisibility();
    window.addEventListener("scroll", updateVisibility, { passive: true });
    window.addEventListener("resize", updateVisibility);
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", updateVisibility);
    }
    window.addEventListener("load", updateVisibility);
  }

  function openAncestorsFromLink(root, link) {
    var node = link.parentElement;
    var changed = false;
    while (node) {
      if (node.classList && node.classList.contains("jtoc-item")) {
        if (!node.classList.contains("is-open")) {
          node.classList.add("is-open");
          changed = true;
        }
      }
      node = node.parentElement;
    }
    if (changed) {
      refreshFoldHeights(root);
    }
    return changed;
  }

  function setupFold(root) {
    if (root.dataset.fold !== "true") {
      captureInitialNavContentHeightOnce(root);
      applyPanelMaxHeight(root);
      return;
    }

    var items = root.querySelectorAll(".jtoc-item.has-children");
    var minDisplayLevel = Number.POSITIVE_INFINITY;

    items.forEach(function (item) {
      var displayLevel = Number(item.dataset.jtocDisplayLevel || 0);
      if (displayLevel >= 0 && displayLevel < minDisplayLevel) {
        minDisplayLevel = displayLevel;
      }
    });

    if (Number.isFinite(minDisplayLevel)) {
      items.forEach(function (item) {
        var displayLevel = Number(item.dataset.jtocDisplayLevel || 0);
        if (displayLevel === minDisplayLevel) {
          item.classList.add("is-open");
        }
      });
    }

    function ensureActiveVisibleAfterLayoutChange() {
      var scrollEl = getTocScrollContainer(root);
      var activeLink = root.querySelector(".jtoc-link.is-active");
      if (!scrollEl || !activeLink) {
        return;
      }

      var viewRect = scrollEl.getBoundingClientRect();
      var linkRect = activeLink.getBoundingClientRect();
      var topGuard = viewRect.top + 36;
      var bottomGuard = viewRect.bottom - 12;
      var isOutside = linkRect.top < topGuard || linkRect.bottom > bottomGuard;
      if (!isOutside) {
        return;
      }

      var relativeTop = linkRect.top - viewRect.top + scrollEl.scrollTop;
      var targetTop = relativeTop - scrollEl.clientHeight * 0.35;
      scrollEl.scrollTo({ top: Math.max(0, targetTop), behavior: "smooth" });
    }

    items.forEach(function (item) {
      var toggle = getDirectToggle(item);
      if (!toggle) {
        return;
      }

      toggle.addEventListener("click", function (event) {
        event.preventDefault();
        event.stopPropagation();
        item.classList.toggle("is-open");
        refreshFoldHeights(root);
      });
    });

    root.classList.add("jtoc-fold-init");
    refreshFoldHeights(root);
    ensureActiveVisibleAfterLayoutChange();
    window.requestAnimationFrame(function () {
      window.requestAnimationFrame(function () {
        root.classList.remove("jtoc-fold-init");
      });
    });

    window.addEventListener("resize", function () {
      refreshFoldHeights(root);
    });
  }

  function setupScrollSpy(root) {
    var links = Array.prototype.slice.call(root.querySelectorAll(".jtoc-link"));
    var panel = root.querySelector(".jtoc-panel");
    var scrollEl = getTocScrollContainer(root);
    if (!links.length || !panel || !scrollEl) {
      return;
    }

    var headings = links
      .map(function (link) {
        var id = (link.getAttribute("href") || "").replace(/^#/, "");
        if (!id) {
          return null;
        }
        var heading = document.getElementById(id);
        if (!heading) {
          return null;
        }
        return { id: id, heading: heading, link: link };
      })
      .filter(Boolean);

    if (!headings.length) {
      return;
    }

    var currentActiveId = null;

    function getLinkById(id) {
      for (var i = 0; i < links.length; i += 1) {
        if (links[i].dataset.jtocLink === id) {
          return links[i];
        }
      }
      return null;
    }

    function setActive(id) {
      if (!id) {
        return;
      }

      if (id === currentActiveId) {
        return;
      }

      var activeLink = null;
      links.forEach(function (link) {
        var linkId = link.dataset.jtocLink;
        var isActive = linkId === id;
        link.classList.toggle("is-active", isActive);
        var row = link.closest(".jtoc-link-row");
        if (row) {
          row.classList.toggle("is-active", isActive);
        }
        if (isActive) {
          activeLink = link;
        }
        if (isActive && root.dataset.fold === "true") {
          var changed = openAncestorsFromLink(root, link);
          if (changed) {
            trackActiveLinkDuringUnfold(link);
          }
        }
      });
      currentActiveId = id;
      ensureActiveLinkVisible(activeLink);
    }

    function ensureActiveLinkVisible(activeLink) {
      if (!activeLink) {
        return;
      }

      var viewRect = scrollEl.getBoundingClientRect();
      var linkRect = activeLink.getBoundingClientRect();
      var topGuard = viewRect.top + 36;
      var bottomGuard = viewRect.bottom - 12;
      var isOutside = linkRect.top < topGuard || linkRect.bottom > bottomGuard;
      if (!isOutside) {
        return;
      }

      var relativeTop = linkRect.top - viewRect.top + scrollEl.scrollTop;
      var targetTop = relativeTop - scrollEl.clientHeight * 0.35;
      if (linkRect.top - viewRect.top <= scrollEl.clientHeight * 0.2) {
        targetTop = 0;
      }
      targetTop = Math.max(0, targetTop);
      scrollEl.scrollTo({ top: targetTop, behavior: "auto" });
    }

    function ensureCurrentActiveVisible() {
      if (!currentActiveId) {
        return;
      }
      ensureActiveLinkVisible(getLinkById(currentActiveId));
    }

    function trackActiveLinkDuringUnfold(activeLink) {
      if (!activeLink) {
        return;
      }

      var endAt = Date.now() + 700;
      function frameTrack() {
        ensureCurrentActiveVisible();
        if (Date.now() < endAt) {
          window.requestAnimationFrame(frameTrack);
        }
      }
      window.requestAnimationFrame(frameTrack);
    }

    var observer = new IntersectionObserver(
      function (entries) {
        var visible = entries
          .filter(function (entry) {
            return entry.isIntersecting;
          })
          .sort(function (a, b) {
            return a.boundingClientRect.top - b.boundingClientRect.top;
          });

        if (visible.length) {
          setActive(visible[0].target.id);
        }
      },
      {
        rootMargin: "-20% 0px -65% 0px",
        threshold: [0.1, 0.4, 0.8]
      }
    );

    headings.forEach(function (item) {
      observer.observe(item.heading);
    });

    function setActiveByHash() {
      var hash = (window.location.hash || "").replace(/^#/, "");
      if (!hash) {
        return;
      }
      setActive(hash);
    }

    function setActiveByScrollPosition() {
      var offsetY = 140;
      var current = headings[0];
      headings.forEach(function (item) {
        if (item.heading.getBoundingClientRect().top <= offsetY) {
          current = item;
        }
      });
      if (current) {
        setActive(current.id);
      }
    }

    links.forEach(function (link) {
      link.addEventListener("click", function () {
        var id = (link.getAttribute("href") || "").replace(/^#/, "");
        if (!id) {
          return;
        }
        setActive(id);
      });
    });

    window.addEventListener("hashchange", setActiveByHash);
    window.addEventListener(
      "scroll",
      function () {
        setActiveByScrollPosition();
      },
      { passive: true }
    );

    window.addEventListener("resize", function () {
      ensureCurrentActiveVisible();
    });

    panel.addEventListener(
      "transitionrun",
      function (event) {
        if (!event.target.classList || !event.target.classList.contains("jtoc-list")) {
          return;
        }
        if (!currentActiveId) {
          return;
        }
        var activeLink = getLinkById(currentActiveId);
        if (!activeLink || !event.target.contains(activeLink)) {
          return;
        }
        trackActiveLinkDuringUnfold(activeLink);
      },
      true
    );

    panel.addEventListener(
      "transitionend",
      function (event) {
        if (!event.target.classList || !event.target.classList.contains("jtoc-list")) {
          return;
        }
        if (!currentActiveId) {
          return;
        }
        var activeLink = getLinkById(currentActiveId);
        if (!activeLink || !event.target.contains(activeLink)) {
          return;
        }
        ensureCurrentActiveVisible();
      },
      true
    );

    setActiveByHash();
    setActiveByScrollPosition();
  }

  function init() {
    var root = document.querySelector("[data-jtoc-root]");
    if (!root) {
      return;
    }

    root.classList.add("jtoc-panel-layout-init");

    var config = parseConfig();
    var runtimeStyle = resolveRuntimeStyle(config);
    applyRuntimeStyle(root, runtimeStyle);
    observeThemeChanges(root, runtimeStyle);
    setupMobileToggle(root);
    setupFold(root);
    setupScrollEdgeVisibility(root);

    function bindScrollSpyAndUnlock() {
      setupScrollSpy(root);
      window.requestAnimationFrame(function () {
        window.requestAnimationFrame(function () {
          root.classList.remove("jtoc-panel-layout-init");
        });
      });
    }

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bindScrollSpyAndUnlock);
    } else {
      bindScrollSpyAndUnlock();
    }
  }

  if (document.querySelector("[data-jtoc-root]")) {
    init();
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
