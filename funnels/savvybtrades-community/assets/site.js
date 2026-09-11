/* The Payout Room — page behaviour. No dependencies. */
(function () {
  "use strict";

  var cfg = window.PAYOUT_ROOM_CONFIG || {};

  /* ---- Config wiring -------------------------------------------------- */

  // Remember campaign parameters from the first page someone lands on so
  // they travel with the lead when the form is submitted.
  var UTM_KEYS = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"];
  try {
    var qs = new URLSearchParams(location.search);
    var found = {};
    UTM_KEYS.forEach(function (k) { if (qs.get(k)) found[k] = qs.get(k); });
    if (Object.keys(found).length) sessionStorage.setItem("pr_utm", JSON.stringify(found));
    if (!sessionStorage.getItem("pr_ref") && document.referrer) sessionStorage.setItem("pr_ref", document.referrer);
  } catch (e) { /* storage unavailable, carry on */ }
  if (cfg.instagramUrl) {
    document.querySelectorAll("[data-instagram]").forEach(function (a) {
      a.setAttribute("href", cfg.instagramUrl);
      a.setAttribute("target", "_blank");
      a.setAttribute("rel", "noopener");
    });
  }
  if (cfg.discordUrl) {
    document.querySelectorAll("[data-discord]").forEach(function (a) {
      a.setAttribute("href", cfg.discordUrl);
      a.setAttribute("target", "_blank");
      a.setAttribute("rel", "noopener");
    });
  }

  /* ---- Hero visual: video if configured, otherwise the chart --------- */

  var visual = document.getElementById("hero-visual");
  if (visual && cfg.videoEmbedUrl) {
    visual.innerHTML =
      '<div class="chart-card"><div class="video-frame">' +
      '<iframe src="' + cfg.videoEmbedUrl + '" title="How the Payout Room works" ' +
      'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>' +
      "</div></div>";
  } else {
    drawKeyLevels(document.getElementById("chart-svg"));
  }

  /* ---- Key levels chart ------------------------------------------------
     A deterministic candlestick series with three marked levels. It is an
     illustration of the method (levels drawn ahead of time, price reacting
     to them), not real market data.                                       */

  function drawKeyLevels(svg) {
    if (!svg) return;
    var W = 640, H = 360;
    var padL = 18, padR = 78, padT = 22, padB = 30;
    var n = 46;

    // Seeded PRNG so the picture is stable across loads.
    var seed = 20240917;
    function rnd() {
      seed = (seed * 1664525 + 1013904223) % 4294967296;
      return seed / 4294967296;
    }

    // Levels: three key levels Brad would have marked on Sunday.
    var levels = [5288.50, 5241.25, 5196.75];

    // Walk price so it respects the levels: rejects the top, bounces the mid,
    // then breaks out of the top.
    var candles = [];
    var p = 5222;
    for (var i = 0; i < n; i++) {
      var drift = 0;
      if (i < 12) drift = 5.5;              // grind up to the top level
      else if (i < 18) drift = -6.5;        // reject
      else if (i < 27) drift = -1.5;        // drift into the mid level
      else if (i < 33) drift = 5.0;         // bounce
      else drift = 4.0;                     // break through and hold above
      var open = p;
      var move = drift + (rnd() - 0.5) * 9;
      var close = open + move;
      // Respect the levels early on.
      if (i < 18 && close > levels[0] - 1) close = levels[0] - 1 - rnd() * 3;
      if (i >= 18 && i < 33 && close < levels[1] + 1) close = levels[1] + 1 + rnd() * 3;
      var hi = Math.max(open, close) + rnd() * 5;
      var lo = Math.min(open, close) - rnd() * 5;
      if (i < 18 && hi > levels[0] + 1.5) hi = levels[0] + rnd() * 1.5;
      candles.push({ o: open, c: close, h: hi, l: lo });
      p = close;
    }

    var min = Infinity, max = -Infinity;
    candles.forEach(function (c) { min = Math.min(min, c.l); max = Math.max(max, c.h); });
    min = Math.min(min, levels[2]) - 6;
    max = Math.max(max, levels[0]) + 10;

    var plotW = W - padL - padR, plotH = H - padT - padB;
    function y(v) { return padT + (max - v) / (max - min) * plotH; }
    var step = plotW / n, bw = Math.max(4, step * 0.58);

    var ns = "http://www.w3.org/2000/svg";
    function el(tag, attrs, text) {
      var e = document.createElementNS(ns, tag);
      for (var k in attrs) e.setAttribute(k, attrs[k]);
      if (text != null) e.textContent = text;
      return e;
    }

    svg.setAttribute("viewBox", "0 0 " + W + " " + H);
    svg.setAttribute("role", "img");
    svg.setAttribute("aria-label", "Candlestick chart with three key levels marked. Price rejects the upper level, bounces off the middle level, then breaks out above.");

    var css = getComputedStyle(document.documentElement);
    var brass = css.getPropertyValue("--accent").trim() || "#2244ff";
    var up = css.getPropertyValue("--up").trim() || "#17a86b";
    var down = css.getPropertyValue("--down").trim() || "#e0474f";
    var muted = css.getPropertyValue("--muted").trim() || "#6f727a";
    var grid = css.getPropertyValue("--chart-grid").trim() || "rgba(17,18,20,0.06)";

    // Horizontal grid
    for (var g = 0; g < 5; g++) {
      var gy = padT + plotH * g / 4;
      svg.appendChild(el("line", { x1: padL, y1: gy, x2: W - padR, y2: gy, stroke: grid, "stroke-width": 1 }));
    }

    // Level bands + labels
    levels.forEach(function (lv, idx) {
      var ly = y(lv);
      svg.appendChild(el("rect", { x: padL, y: ly - 6, width: plotW, height: 12, fill: brass, opacity: 0.05 }));
      svg.appendChild(el("line", { x1: padL, y1: ly, x2: W - padR, y2: ly, stroke: brass, "stroke-width": 1.25, "stroke-dasharray": "6 5", opacity: 0.9 }));
      var tag = el("g", {});
      tag.appendChild(el("rect", { x: W - padR + 8, y: ly - 10, width: padR - 14, height: 20, rx: 4, fill: brass }));
      tag.appendChild(el("text", {
        x: W - padR + 8 + (padR - 14) / 2, y: ly + 4, "text-anchor": "middle",
        "font-family": "Onest, Helvetica Neue, Arial, sans-serif", "font-size": 10.5, "font-weight": 600, fill: "#ffffff"
      }, lv.toFixed(2)));
      svg.appendChild(tag);
      var name = idx === 0 ? "KEY LEVEL · RESISTANCE" : idx === 1 ? "KEY LEVEL · SUPPORT" : "KEY LEVEL · LOW";
      svg.appendChild(el("text", {
        x: padL + 4, y: ly - 9, "font-family": "Onest, Helvetica Neue, Arial, sans-serif", "font-size": 9.5,
        "letter-spacing": 1.2, "font-weight": 600, fill: brass, opacity: 0.9
      }, name));
    });

    // Candles
    candles.forEach(function (c, i) {
      var cx = padL + step * i + step / 2;
      var bull = c.c >= c.o;
      var col = bull ? up : down;
      svg.appendChild(el("line", { x1: cx, y1: y(c.h), x2: cx, y2: y(c.l), stroke: col, "stroke-width": 1.2 }));
      var top = y(Math.max(c.o, c.c)), bot = y(Math.min(c.o, c.c));
      svg.appendChild(el("rect", {
        x: cx - bw / 2, y: top, width: bw, height: Math.max(1.5, bot - top), rx: 1,
        fill: bull ? col : col, opacity: bull ? 1 : 0.95
      }));
    });

    // Entry marker on the bounce candle and the breakout candle
    function marker(i, label, above) {
      var c = candles[i];
      var cx = padL + step * i + step / 2;
      var my = above ? y(c.h) - 14 : y(c.l) + 14;
      svg.appendChild(el("circle", { cx: cx, cy: my, r: 4, fill: brass }));
      svg.appendChild(el("circle", { cx: cx, cy: my, r: 9, fill: "none", stroke: brass, "stroke-width": 1, opacity: 0.5 }));
      svg.appendChild(el("text", {
        x: cx + 14, y: my + 4, "font-family": "Onest, Helvetica Neue, Arial, sans-serif", "font-size": 10,
        "letter-spacing": 1, fill: muted
      }, label));
    }
    marker(27, "BOUNCE", false);
    marker(36, "BREAK + HOLD", true);

    // Last price line
    var last = candles[n - 1].c;
    svg.appendChild(el("line", { x1: padL, y1: y(last), x2: W - padR, y2: y(last), stroke: up, "stroke-width": 1, "stroke-dasharray": "2 3", opacity: 0.7 }));
    var lp = el("g", {});
    lp.appendChild(el("rect", { x: W - padR + 8, y: y(last) - 10, width: padR - 14, height: 20, rx: 4, fill: up }));
    lp.appendChild(el("text", {
      x: W - padR + 8 + (padR - 14) / 2, y: y(last) + 4, "text-anchor": "middle",
      "font-family": "Onest, Helvetica Neue, Arial, sans-serif", "font-size": 10.5, "font-weight": 600, fill: "#ffffff"
    }, last.toFixed(2)));
    svg.appendChild(lp);

    // Time axis
    ["09:30", "10:30", "11:30", "12:30", "13:30"].forEach(function (t, i) {
      svg.appendChild(el("text", {
        x: padL + plotW * i / 4, y: H - 10, "font-family": "Onest, Helvetica Neue, Arial, sans-serif",
        "font-size": 9.5, fill: muted, "text-anchor": i === 0 ? "start" : i === 4 ? "end" : "middle"
      }, t));
    });
  }

  /* ---- Sticky mobile CTA: show once the hero CTA has scrolled away ---- */

  var sticky = document.getElementById("sticky-cta");
  var heroCta = document.getElementById("hero-cta");
  if (sticky && heroCta && "IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { sticky.classList.toggle("show", !e.isIntersecting); });
    }, { threshold: 0 });
    io.observe(heroCta);
  }

  /* ---- FAQ: close others when one opens ------------------------------- */

  var faqs = document.querySelectorAll(".faq-list details");
  faqs.forEach(function (d) {
    d.addEventListener("toggle", function () {
      if (!d.open) return;
      faqs.forEach(function (o) { if (o !== d) o.open = false; });
    });
  });

  /* ---- Tracking (only when IDs are set in config.js) ------------------- */

  if (cfg.metaPixelId) {
    !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
    n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
    n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
    t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,
    document,'script','https://connect.facebook.net/en_US/fbevents.js');
    window.fbq("init", cfg.metaPixelId);
    window.fbq("track", "PageView");
  }
  if (cfg.gtmId) {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({ "gtm.start": new Date().getTime(), event: "gtm.js" });
    var gtm = document.createElement("script");
    gtm.async = true;
    gtm.src = "https://www.googletagmanager.com/gtm.js?id=" + encodeURIComponent(cfg.gtmId);
    document.head.appendChild(gtm);
  }
  function track(eventName, data) {
    try { if (window.fbq) window.fbq("track", eventName, data || {}); } catch (e) {}
    try { (window.dataLayer = window.dataLayer || []).push(Object.assign({ event: eventName }, data || {})); } catch (e) {}
  }

  /* ---- Opt-in form (/checkout) ---------------------------------------- */

  var form = document.getElementById("lead-form");
  if (form) {
    var status = document.getElementById("form-status");
    var submit = document.getElementById("lead-submit");
    var label = submit.querySelector(".label");

    function setStatus(msg, ok) {
      status.textContent = msg || "";
      status.classList.toggle("ok", !!ok);
    }
    function markInvalid(input, bad) {
      input.setAttribute("aria-invalid", bad ? "true" : "false");
    }

    form.addEventListener("submit", function (ev) {
      ev.preventDefault();
      setStatus("");

      var first = form.first_name, email = form.email, phone = form.phone, consent = form.consent_sms;
      var digits = phone.value.replace(/\D/g, "");
      var problems = [];
      markInvalid(first, !first.value.trim());
      markInvalid(email, !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.value.trim()));
      markInvalid(phone, digits.length < 10);
      if (first.getAttribute("aria-invalid") === "true") problems.push("your first name");
      if (email.getAttribute("aria-invalid") === "true") problems.push("a valid email");
      if (phone.getAttribute("aria-invalid") === "true") problems.push("a mobile number");
      if (!consent.checked) problems.push("the consent box");
      if (problems.length) {
        setStatus("Add " + problems.join(", ").replace(/, ([^,]*)$/, " and $1") + " to continue.");
        return;
      }

      var utm = {};
      try { utm = JSON.parse(sessionStorage.getItem("pr_utm") || "{}"); } catch (e) {}
      var payload = {
        first_name: first.value.trim(),
        last_name: "",
        email: email.value.trim(),
        phone: phone.value.trim(),
        consent_sms: true,
        consent_text: (document.getElementById("consent-text") || {}).textContent || "",
        website: form.website ? form.website.value : "",
        page_url: location.href,
        referrer: (function () { try { return sessionStorage.getItem("pr_ref") || document.referrer; } catch (e) { return document.referrer; } })(),
      };
      UTM_KEYS.forEach(function (k) { payload[k] = utm[k] || ""; });

      submit.disabled = true;
      label.textContent = "Saving…";

      fetch("/api/lead", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })
        .then(function (r) { return r.json().catch(function () { return { ok: r.ok }; }).then(function (j) { j.status = r.status; return j; }); })
        .then(function (j) {
          if (!j.ok) throw new Error(j.error || "Something went wrong. Try again.");
          track("Lead", { content_name: "The Payout Room", currency: "USD", value: 27 });
          setStatus("Saved. Taking you to checkout…", true);
          label.textContent = "One moment…";
          var next = cfg.checkoutUrl || "/thanks";
          if (cfg.checkoutUrl && /stripe\.com|buy\.stripe/.test(cfg.checkoutUrl)) {
            next += (next.indexOf("?") > -1 ? "&" : "?") + "prefilled_email=" + encodeURIComponent(payload.email);
          }
          setTimeout(function () { location.href = next; }, 350);
        })
        .catch(function (err) {
          setStatus(err.message || "Something went wrong. Try again.");
          submit.disabled = false;
          label.textContent = "Continue to checkout";
        });
    });
  }

  /* ---- Footer year ----------------------------------------------------- */

  document.querySelectorAll("[data-year]").forEach(function (e) {
    e.textContent = new Date().getFullYear();
  });
})();
