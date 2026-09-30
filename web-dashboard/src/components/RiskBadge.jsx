const CONFIG = {
  low: { label: 'Low risk', color: 'var(--risk-low-dark)', bg: 'var(--risk-low-surface)' },
  medium: { label: 'Medium risk', color: 'var(--risk-medium-dark)', bg: 'var(--risk-medium-surface)' },
  high: { label: 'High risk', color: 'var(--risk-high-dark)', bg: 'var(--risk-high-surface)' },
};

export default function RiskBadge({ level, size = 'md' }) {
  if (!level) return <span className="risk-badge risk-badge--none">No screening yet</span>;
  const cfg = CONFIG[level] || CONFIG.low;
  return (
    <span
      className={`risk-badge risk-badge--${size}`}
      style={{ color: cfg.color, background: cfg.bg }}
    >
      <span className="risk-badge__dot" style={{ background: cfg.color }} />
      {cfg.label}
    </span>
  );
}
