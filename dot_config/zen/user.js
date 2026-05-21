// Theme / Zen
user_pref("zen.theme.essentials-favicon-bg", false);
user_pref("zen.theme.accent-color", "#89b4fa");
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// Display / Rendering
user_pref("widget.dmabuf.force-enabled", true);
user_pref("gfx.font_rendering.fontconfig.max_generic_substitutions", 127);
user_pref("gfx.webrender.layer-compositor", true);
user_pref("media.wmf.zero-copy-nv12-textures-force-enabled", true);
user_pref("gfx.webrender.quality.force-subpixel-aa-where-possible", true);
user_pref("gfx.use_text_smoothing_setting", true);

// Accessibility
user_pref("accessibility.force_disabled", 1);
user_pref("devtools.accessibility.enabled", false);

// DevTools / View source
user_pref("view_source.wrap_long_lines", true);
user_pref("devtools.debugger.ui.editor-wrapping", true);

// UX / Editor
user_pref("dom.confirm_repost.testing.always_accept", true);
user_pref("layout.word_select.eat_space_to_next_word", false);
user_pref("ui.SpellCheckerUnderlineStyle", 1);
user_pref("browser.menu.showViewImageInfo", true);
user_pref("browser.bookmarks.openInTabClosesMenu", false);
user_pref("browser.tabs.unloadTabInContextMenu", false);

// PDF / Reader
user_pref("pdfjs.defaultZoomValue", "page-width");
user_pref("reader.parse-on-load.enabled", false);
user_pref("browser.download.open_pdf_attachments_inline", true);

// Bookmarks
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("browser.bookmarks.max_backups", 0);
user_pref("browser.urlbar.suggest.bookmark", false);

// URL bar
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.trimHttps", true);
user_pref("browser.urlbar.untrimOnUserInteraction.featureGate", true);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.groupLabels.enabled", false);
user_pref("browser.urlbar.trending.featureGate", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);

// Search
user_pref("browser.search.update", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.search.separatePrivateDefault.ui.enabled", true);

// Forms / Autofill / Logins
user_pref("signon.autofillForms", false);
user_pref("signon.formlessCapture.enabled", false);
user_pref("signon.privateBrowsingCapture.enabled", false);
user_pref("browser.formfill.enable", false);
user_pref("security.insecure_field_warning.contextual.enabled", false);
user_pref("security.insecure_password.ui.enabled", false);

// Sessions
user_pref("browser.sessionhistory.max_total_viewers", 8);
user_pref("browser.sessionstore.interval", 60000);
user_pref("browser.firefox-view.feature-tour", "{\"screen\":\"\",\"complete\":true}");

// Cache & memory
user_pref("browser.cache.disk.enable", false);
user_pref("browser.privatebrowsing.forceMediaMemoryCache", true);
user_pref("media.memory_cache_max_size", 65536);

// Privacy / tracking
user_pref("privacy.history.custom", true);
user_pref("privacy.globalprivacycontrol.enabled", true);
user_pref("privacy.antitracking.isolateContentScriptResources", true);
user_pref("privacy.resistFingerprinting.block_mozAddonManager", true);
user_pref("browser.privatebrowsing.resetPBM.enabled", true);
user_pref("browser.contentblocking.category", "strict");
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);
user_pref("network.IDN_show_punycode", true);
user_pref("media.peerconnection.ice.default_address_only", true);

// Security / TLS / certs
user_pref("dom.security.https_only_mode", false);
user_pref("dom.security.https_only_mode_pbm", true);
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.OCSP.enabled", 0);
user_pref("security.csp.reporting.enabled", false);
user_pref("security.ssl.treat_unsafe_negotiation_as_broken", true);
user_pref("security.tls.enable_0rtt_data", false);
user_pref("browser.xul.error_pages.expert_bad_cert", true);

// Network / DNS / prefetch
user_pref("network.trr.mode", 5);
user_pref("network.trr.max-fails", 5);
user_pref("network.trr.confirmationNS", "skip");
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("network.dns.echconfig.enabled", true);
user_pref("network.dns.http3_echconfig.enabled", true);

// Downloads / Safe Browsing
user_pref("browser.download.start_downloads_in_tmp_dir", true);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.allowOverride", false);

// Permissions
user_pref("permissions.default.desktop-notification", 2);
user_pref("permissions.default.geo", 2);
user_pref("geo.provider.network.url", "https://beacondb.net/v1/geolocate");
user_pref("permissions.manager.defaultsUrl", "");

// Extensions
user_pref("extensions.webextensions.restrictedDomains", "");
user_pref("extensions.enabledScopes", 5);
user_pref("extensions.getAddons.cache.enabled", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);

// Telemetry / crash reporting
user_pref("datareporting.usage.uploadEnabled", false);
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);

// Bloat
user_pref("browser.uitour.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);

// ML / AI
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.menu", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);

// New tab
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);

// Binds / Scrolling
user_pref("mousewheel.with_shift.action", 5);
user_pref("ui.key.chromeAccess", 5);
user_pref("apz.overscroll.enabled", true);
user_pref("general.smoothScroll", true);
user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 12);
user_pref("general.smoothScroll.msdPhysics.enabled", true);
user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 25);
user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "2");
user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
user_pref("general.smoothScroll.currentVelocityWeighting", "1");
user_pref("general.smoothScroll.stopDecelerationWeighting", "1");
user_pref("mousewheel.default.delta_multiplier_y", 300);

