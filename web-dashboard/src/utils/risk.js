export const RISK_STYLES = {
  low: { color: 'var(--risk-low-dark)', bg: 'var(--risk-low-surface)', border: 'var(--risk-low)' },
  medium: { color: 'var(--risk-medium-dark)', bg: 'var(--risk-medium-surface)', border: 'var(--risk-medium)' },
  high: { color: 'var(--risk-high-dark)', bg: 'var(--risk-high-surface)', border: 'var(--risk-high)' },
};

export function riskStyle(level) {
  return RISK_STYLES[level] || RISK_STYLES.low;
}
