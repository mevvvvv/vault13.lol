/* ==== CORE UTILITIES ==== */
const $ = id => document.getElementById(id);
let user = null, isAdmin = false;
let startTime = Date.now();

/* ==== PLATFORMS ==== */
const platforms = { /* ... same as before ... */ };

/* ==== CROSSHAIR ==== */
document.addEventListener('mousemove', e => {
    const crosshair = $('crosshair');
    if (crosshair) {
        crosshair.style.left = e.clientX + 'px';
        crosshair.style.top = e.clientY + 'px';
        crosshair.style.display = 'block';
    }
});

/* ==== STARS, UPTIME, TERM, ANIMATIONS ==== */
function createStars() { /* ... same ... */ }
function updateUptime() { /* ... same ... */ }
function term(id,msg,color,success=false){ /* ... same ... */ }
function animateValue(id,start,end,dur){ /* ... same ... */ }
function setAvatar(src){ /* ... same ... */ }
function updateVisitors() { /* ... same ... */ }

/* ==== DASHBOARD LOAD ==== */
function goDash(u) {
    user = u;
    const p = JSON.parse(localStorage.getItem(`profile_${u}`));
    isAdmin = u === 'xen';
    /* ... all the same dashboard population code ... */
    dash.classList.add('active');
}

/* ==== PROFILE LOAD ==== */
function loadProfile(u) {
    const p = JSON.parse(localStorage.getItem(`profile_${u}`)) || { /* defaults */ };
    /* ... all the same profile population code ... */
    profile.classList.add('active');
}

/* ==== NAVIGATION HELPERS ==== */
function navigateTo(page) { location.href = page; }
function goToLogin() { navigateTo('login.html'); }
function goToSignup() { navigateTo('signup.html'); }
function goToDashboard(u) { navigateTo(`dashboard.html?u=${u}`); }