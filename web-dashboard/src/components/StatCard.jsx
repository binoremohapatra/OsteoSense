export default function StatCard({ label, value, accent, icon: Icon, sub }) {
  return (
    <div className="stat-card">
      <div className="stat-card__top">
        <span className="stat-card__label">{label}</span>
        {Icon && (
          <span className="stat-card__icon" style={{ background: accent ? `${accent}1A` : 'var(--primary-surface)', color: accent || 'var(--primary)' }}>
            <Icon size={16} strokeWidth={2.25} />
          </span>
        )}
      </div>
      <div className="stat-card__value">{value}</div>
      {sub && <div className="stat-card__sub">{sub}</div>}
    </div>
  );
}
