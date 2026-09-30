import { useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import KneeDeviceExplodedView from './KneeDeviceExplodedView';
import {
  Activity, Users, Stethoscope, BarChart3, CloudOff, HeartPulse,
  ArrowRight, CheckCircle2, ShieldCheck, Smartphone, MapPin, Cpu, Waves, Zap,
} from 'lucide-react';
import './Landing.css';

const FEATURES = [
  { icon: Users, title: 'Patient management', body: 'Keep every patient record organised and easy to find across field visits.' },
  { icon: Stethoscope, title: 'AI-assisted screening', body: 'Capture symptoms and gait readings and return a clear, actionable risk result.' },
  { icon: BarChart3, title: 'Field analytics', body: 'See screening activity, risk distribution and trends from one workspace.' },
  { icon: CloudOff, title: 'Works without signal', body: 'Offline screenings can queue locally and sync when connectivity returns.' },
  { icon: HeartPulse, title: 'Preventive care', body: 'Give patients practical exercise, lifestyle and follow-up guidance.' },
  { icon: Activity, title: 'Longitudinal history', body: 'Connect screenings to the patient record to follow changing risk over time.' },
];

const STEPS = [
  { n: '01', title: 'Screen', body: 'Capture symptoms, mobility signals and patient details in a focused workflow.' },
  { n: '02', title: 'Assess', body: 'JointSaathi turns the screening inputs into an understandable risk assessment.' },
  { n: '03', title: 'Act', body: 'Use the result, reasoning and care guidance to decide the next step.' },
];

const MARQUEE = ['IMU motion sensing', 'Piezo joint acoustics', '3-lead EMG', 'Offline-first sync', 'AI risk assessment', 'Modular & removable', 'Field-ready', 'Preventive guidance'];

const SPECS = [
  { icon: Cpu, k: 'ESP32', v: 'On-board controller' },
  { icon: Activity, k: 'MPU6050 IMU', v: 'Knee angle & gait' },
  { icon: Waves, k: 'Piezo disc', v: 'Joint vibration' },
  { icon: Zap, k: '3-lead EMG', v: 'Muscle activity' },
];

/* Counts a number up once it scrolls into view */
function Counter({ to, pad = 0 }) {
  const ref = useRef(null);
  useEffect(() => {
    const el = ref.current;
    let raf;
    const io = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return;
      io.disconnect();
      const t0 = performance.now();
      const tick = (t) => {
        const k = Math.min(1, (t - t0) / 1400);
        el.textContent = String(Math.round(to * (1 - Math.pow(1 - k, 3)))).padStart(pad, '0');
        if (k < 1) raf = requestAnimationFrame(tick);
      };
      raf = requestAnimationFrame(tick);
    });
    io.observe(el);
    return () => { io.disconnect(); cancelAnimationFrame(raf); };
  }, [to, pad]);
  return <span ref={ref}>{String(to).padStart(pad, '0')}</span>;
}

/* Scroll reveal, scroll-progress bar, hero pointer parallax, card spotlight */
function useLandingFx(rootRef) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return undefined;
    root.classList.add('fx');
    const io = new IntersectionObserver((entries) => entries.forEach((e) => {
      if (e.isIntersecting) { e.target.classList.add('is-in'); io.unobserve(e.target); }
    }), { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
    root.querySelectorAll('.reveal').forEach((el) => io.observe(el));

    const bar = root.querySelector('.landing__progress');
    const hero = root.querySelector('.landing__hero-visual');
    let raf = 0;
    const onScroll = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const d = document.documentElement;
        bar.style.transform = `scaleX(${d.scrollTop / Math.max(1, d.scrollHeight - d.clientHeight)})`;
      });
    };
    const onMove = (e) => {
      hero.style.setProperty('--mx', (e.clientX / window.innerWidth - 0.5).toFixed(3));
      hero.style.setProperty('--my', (e.clientY / window.innerHeight - 0.5).toFixed(3));
      const card = e.target.closest && e.target.closest('.feature-card');
      if (card) {
        const r = card.getBoundingClientRect();
        card.style.setProperty('--sx', `${e.clientX - r.left}px`);
        card.style.setProperty('--sy', `${e.clientY - r.top}px`);
      }
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('pointermove', onMove, { passive: true });
    onScroll();
    return () => {
      io.disconnect();
      cancelAnimationFrame(raf);
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('pointermove', onMove);
    };
  }, [rootRef]);
}

export default function Landing() {
  const rootRef = useRef(null);
  useLandingFx(rootRef);
  return (
    <div className="landing" ref={rootRef}>
      <div className="landing__progress" aria-hidden="true" />

      <div className="landing__ambient" aria-hidden="true">
        <span className="ambient-circle ambient-circle--1" />
        <span className="ambient-circle ambient-circle--2" />
        <span className="ambient-circle ambient-circle--3" />
        <span className="ambient-circle ambient-circle--4" />
        <span className="ambient-circle ambient-circle--5" />
        <span className="ambient-circle ambient-circle--6" />
        <span className="ambient-circle ambient-circle--7" />
        <span className="ambient-circle ambient-circle--8" />
        <span className="ambient-circle ambient-circle--9" />
        <span className="ambient-circle ambient-circle--10" />
      </div>

      <header className="landing__nav">
        <Link to="/" className="landing__brand" aria-label="JointSaathi home">
          <span className="landing__brand-mark">
            <img src="/favicon.jpeg" alt="JointSaathi" className="landing__brand-logo" />
          </span>
          <span></span>
        </Link>
        <nav className="landing__links" aria-label="Primary navigation">
          <a href="#how-it-works">How it works</a>
          <a href="#device">The device</a>
          <a href="#capabilities">Capabilities</a>
          <a href="#trust">Trust</a>
        </nav>
        <div className="landing__actions">
          <Link to="/login" className="landing__login" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}>
            <ShieldCheck size={14} /> Admin Login
          </Link>
          <Link to="/login" className="btn btn-primary btn-sm">Admin Portal <ArrowRight size={15} /></Link>
        </div>
      </header>

      <main>
        <section className="landing__hero">
          <div className="landing__hero-copy">
            <span className="landing__eyebrow"><span /> EARLY DETECTION • BETTER MOBILITY</span>
            <h1>Catch osteoarthritis <em>early.</em></h1>
            <p className="landing__lede">
              JointSaathi gives healthcare workers a calm, practical workspace to screen patients,
              understand risk and support preventive care — even when connectivity is limited.
            </p>
            <div className="landing__cta-row">
              <Link to="/login" className="btn btn-primary btn-lg">Admin Login <ArrowRight size={17} /></Link>
              <Link to="/login" className="btn btn-ghost btn-lg">Open Dashboard</Link>
            </div>
            <div className="landing__trust-row">
              <span><ShieldCheck size={16} /> Healthcare-worker focused</span>
              <span><Smartphone size={16} /> Field-ready workflow</span>
              <span><CloudOff size={16} /> Offline-aware</span>
            </div>
          </div>

          <div className="landing__hero-visual" aria-label="JointSaathi product preview">
            <div className="hero-glow hero-glow--one" />
            <div className="hero-glow hero-glow--two" />
            <div className="product-window">
              <div className="product-window__topbar">
                <div className="product-window__dots"><i /><i /><i /></div>
                <span>JointSaathi / Overview</span>
                <span className="product-window__secure"><ShieldCheck size={13} /> Secure</span>
              </div>
              <div className="product-window__body">
                <div className="preview-sidebar">
                  <div className="preview-logo">
                    <img src="/favicon.jpeg" alt="JointSaathi" style={{ width: 18, height: 18, borderRadius: '50%', objectFit: 'cover' }} /> JointSaathi
                  </div>
                  <div className="preview-nav active"><span /> Overview</div>
                  <div className="preview-nav">Patients</div>
                  <div className="preview-nav">Screenings</div>
                  <div className="preview-nav">Analytics</div>
                </div>
                <div className="preview-content">
                  <div className="preview-heading">
                    <div><small>FIELD HEALTH WORKSPACE</small><strong>Good morning, Health Worker</strong></div>
                    <button>+ New screening</button>
                  </div>
                  <div className="preview-stats">
                    <div><span>Total patients</span><b><Counter to={128} /></b><small>+12 this month</small></div>
                    <div><span>Screenings</span><b><Counter to={46} /></b><small>8 today</small></div>
                    <div className="preview-stat--risk"><span>High risk</span><b><Counter to={7} pad={2} /></b><small>Needs attention</small></div>
                  </div>
                  <div className="preview-grid">
                    <div className="preview-panel preview-chart">
                      <div className="preview-panel__head"><strong>Screening activity</strong><span>Last 7 days</span></div>
                      <div className="bars"><i style={{ height: '42%' }} /><i style={{ height: '58%' }} /><i style={{ height: '48%' }} /><i style={{ height: '74%' }} /><i style={{ height: '62%' }} /><i style={{ height: '88%' }} /><i style={{ height: '70%' }} /></div>
                      <div className="chart-axis"><span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span></div>
                    </div>
                    <div className="preview-panel risk-summary">
                      <div className="preview-panel__head"><strong>Risk distribution</strong><span>128 patients</span></div>
                      <div className="donut"><div><b>128</b><span>patients</span></div></div>
                      <div className="risk-legend"><span><i className="low" /> Low <b>84</b></span><span><i className="medium" /> Medium <b>37</b></span><span><i className="high" /> High <b>7</b></span></div>
                    </div>
                  </div>
                  <div className="preview-panel recent-panel">
                    <div className="preview-panel__head"><strong>Recent screening</strong><span>View all</span></div>
                    <div className="preview-row"><div className="mini-avatar">TN</div><div><b>Tenzin Norbu</b><span>Screened today · 10:42 AM</span></div><span className="preview-risk high">High risk</span></div>
                    <div className="preview-row"><div className="mini-avatar teal">AS</div><div><b>Anita Singh</b><span>Screened today · 09:18 AM</span></div><span className="preview-risk low">Low risk</span></div>
                  </div>
                </div>
              </div>
            </div>
            <div className="hero-chip"><span className="hero-chip__label"><Waves size={13} /> LIVE GAIT SIGNAL</span><svg className="wave" viewBox="0 0 120 32" aria-hidden="true"><path pathLength="1" d="M0 16 L14 16 L20 6 L27 26 L33 16 L52 16 L58 4 L66 28 L72 16 L92 16 L98 8 L105 24 L110 16 L120 16" /></svg><b>42°</b></div>
            <div className="hero-callout"><CheckCircle2 size={17} /><div><strong>Screening complete</strong><span>Risk assessment ready in seconds</span></div></div>
          </div>
        </section>

        <section className="landing__proof">
          <span>BUILT FOR REAL-WORLD CARE DELIVERY</span>
          <div><strong>Screen.</strong> <strong>Understand.</strong> <strong>Follow up.</strong></div>
        </section>

        <div className="landing__marquee" aria-hidden="true"><div className="landing__marquee-track">{[...MARQUEE, ...MARQUEE].map((t, i) => <span key={i}><i />{t}</span>)}</div></div>

        <section id="how-it-works" className="landing__section landing__section--process">
          <div className="section-intro reveal"><span className="section-kicker">HOW IT WORKS</span><h2>From symptom to action, without the complexity.</h2><p>A focused workflow keeps the health worker moving while keeping the patient story connected.</p></div>
          <div className="steps">
            {STEPS.map((s, i) => <div className="step reveal" style={{ '--d': `${i * 120}ms` }} key={s.n}><div className="step__top"><span className="step__n">{s.n}</span>{i < 2 && <span className="step__line" />}</div><h3>{s.title}</h3><p>{s.body}</p></div>)}
          </div>
        </section>

        <KneeDeviceExplodedView />
        <div className="device-specs">{SPECS.map((x) => <div key={x.k}><x.icon size={20} /><p><strong>{x.k}</strong><span>{x.v}</span></p></div>)}</div>

        <section id="capabilities" className="landing__section landing__section--tinted">
          <div className="section-intro reveal"><span className="section-kicker">PRODUCT CAPABILITIES</span><h2>One workspace for the full screening journey.</h2><p>Everything needed to organise patients, screen risk, review results and support preventive care.</p></div>
          <div className="feature-grid">{FEATURES.map((f, i) => <article className="feature-card reveal" style={{ '--d': `${(i % 3) * 90}ms` }} key={f.title}><span className="feature-card__icon"><f.icon size={19} /></span><h3>{f.title}</h3><p>{f.body}</p><ArrowRight className="feature-card__arrow" size={17} /></article>)}</div>
        </section>

        <section className="landing__section landing__section--preview">
          <div className="preview-copy"><span className="section-kicker">A REAL PRODUCT INTERFACE</span><h2>Designed around the decisions healthcare workers actually make.</h2><p>Clear signals, readable records and useful context — without turning a clinical workflow into a noisy dashboard.</p><div className="check-list"><span><CheckCircle2 size={17} /> Clear risk signals</span><span><CheckCircle2 size={17} /> Patient history at a glance</span><span><CheckCircle2 size={17} /> Actionable follow-up context</span></div></div>
          <div className="mini-dashboard"><div className="mini-dashboard__head"><span>Patient overview</span><span className="mini-status">Active record</span></div><div className="patient-overview"><div className="patient-avatar">TN</div><div><strong>Tenzin Norbu</strong><span>Last screened today · Tawang</span></div><span className="risk-badge risk-badge--high"><i /> High risk</span></div><div className="patient-metrics"><div><span>Risk score</span><strong>82%</strong></div><div><span>Pain level</span><strong>7 / 10</strong></div><div><span>Stiffness</span><strong>30 min</strong></div></div><div className="recommendation"><span><HeartPulse size={17} /></span><div><strong>Recommended next step</strong><p>Refer for clinical examination and continue follow-up monitoring.</p></div></div></div>
        </section>

        <section id="trust" className="landing__impact"><div><span className="section-kicker section-kicker--light">WHY JOINTSAATHI</span><h2>Technology that stays focused on better mobility.</h2><p>Built to help healthcare teams identify risk earlier, organise care and make every screening more useful.</p></div><div className="impact-metrics"><div><strong>&lt;5s</strong><span>target screening result</span></div><div><strong>24/7</strong><span>patient history access</span></div><div><strong>2</strong><span>care-guidance languages</span></div></div></section>

        <section className="landing__cta"><div><span className="section-kicker">ADMINISTRATIVE COMMAND</span><h2>Centralized screening intelligence &amp; health telemetry.</h2></div><Link to="/login" className="btn btn-accent btn-lg">Access Admin Dashboard <ArrowRight size={17} /></Link></section>
      </main>

      <footer className="landing__footer">
        <span className="landing__brand">
          <span className="landing__brand-mark">
            <img src="/favicon.jpeg" alt="JointSaathi" className="landing__brand-logo" />
          </span>
          JointSaathi
        </span>
        <span>Healthcare screening, designed for the field.</span>
        <span><MapPin size={14} /> North Eastern Region</span>
      </footer>
    </div>
  );
}