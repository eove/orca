// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded "><a href="index.html"><strong aria-hidden="true">1.</strong> Introduction</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="architecture.html"><strong aria-hidden="true">1.1.</strong> Architecture</a></li><li class="chapter-item expanded "><a href="secret_sharing.html"><strong aria-hidden="true">1.2.</strong> Secret Sharing</a></li><li class="chapter-item expanded "><a href="threat_model.html"><strong aria-hidden="true">1.3.</strong> Threat model</a></li></ol></li><li class="chapter-item expanded "><a href="story/index.html"><strong aria-hidden="true">2.</strong> Jules Brown, Hole-in-one&#39;s CTO</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="story/foreword.html"><strong aria-hidden="true">2.1.</strong> Foreword</a></li><li class="chapter-item expanded "><a href="story/the-big-idea.html"><strong aria-hidden="true">2.2.</strong> The big idea</a></li><li class="chapter-item expanded "><a href="story/meet-the-team.html"><strong aria-hidden="true">2.3.</strong> Meet the team</a></li><li class="chapter-item expanded "><a href="story/security-first.html"><strong aria-hidden="true">2.4.</strong> Security first !</a></li><li class="chapter-item expanded "><a href="story/cto-as-security.html"><strong aria-hidden="true">2.5.</strong> CTO as a security guard</a></li><li class="chapter-item expanded "><a href="story/offline-hardware.html"><strong aria-hidden="true">2.6.</strong> Offline hardware</a></li><li class="chapter-item expanded "><a href="story/spof.html"><strong aria-hidden="true">2.7.</strong> Avoiding the single point of failure</a></li><li class="chapter-item expanded "><a href="story/raise-the-bar.html"><strong aria-hidden="true">2.8.</strong> Raise the bar</a></li><li class="chapter-item expanded "><a href="story/never-alone.html"><strong aria-hidden="true">2.9.</strong> Never alone</a></li><li class="chapter-item expanded "><a href="story/need-backup.html"><strong aria-hidden="true">2.10.</strong> Need backup !</a></li><li class="chapter-item expanded "><a href="story/verifiable-os.html"><strong aria-hidden="true">2.11.</strong> Verifiable Operating System</a></li><li class="chapter-item expanded "><a href="story/readonly-usb.html"><strong aria-hidden="true">2.12.</strong> All USB sticks are not created equals</a></li><li class="chapter-item expanded "><a href="story/mfa.html"><strong aria-hidden="true">2.13.</strong> One factor of authentication is not enough</a></li><li class="chapter-item expanded "><a href="story/verify-workflow.html"><strong aria-hidden="true">2.14.</strong> Is this for real ?</a></li><li class="chapter-item expanded "><a href="story/afterword.html"><strong aria-hidden="true">2.15.</strong> Afterword</a></li></ol></li><li class="chapter-item expanded "><a href="testing/index.html"><strong aria-hidden="true">3.</strong> Local testing</a></li><li class="chapter-item expanded "><a href="document_generation.html"><strong aria-hidden="true">4.</strong> Workflow document generation</a></li><li class="chapter-item expanded "><a href="hardware_tokens.html"><strong aria-hidden="true">5.</strong> Hardware tokens</a></li><li class="chapter-item expanded "><a href="gpg_public_key.html"><strong aria-hidden="true">6.</strong> GPG public key</a></li><li class="chapter-item expanded "><a href="pki_init.html"><strong aria-hidden="true">7.</strong> Initialisation</a></li><li class="chapter-item expanded "><a href="revocation.html"><strong aria-hidden="true">8.</strong> Revocation</a></li><li class="chapter-item expanded affix "><li class="spacer"></li><li class="chapter-item expanded affix "><a href="signing_and_verifying.html">Signing and verifying</a></li><li class="chapter-item expanded affix "><a href="glossary.html">Glossary</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString().split("#")[0].split("?")[0];
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
