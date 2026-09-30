import { LineChart, Line, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import EmptyState from './EmptyState';

export default function WaveformChart({ title, data, color = '#4F6757', emptyHint }) {
  if (!data?.length) {
    return (
      <div className="card">
        <h3 className="section-title">{title}</h3>
        <EmptyState title="No samples" message={emptyHint || 'This channel was not included in the synced payload.'} />
      </div>
    );
  }

  return (
    <div className="card">
      <h3 className="section-title">{title}</h3>
      <ResponsiveContainer width="100%" height={220}>
        <LineChart data={data} margin={{ left: -24, top: 8, right: 8 }}>
          <CartesianGrid stroke="var(--divider)" vertical={false} />
          <XAxis dataKey="t" tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }} tickLine={false} axisLine={false} />
          <YAxis tick={{ fontSize: 11, fill: 'var(--text-tertiary)' }} tickLine={false} axisLine={false} />
          <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid var(--border)', fontSize: 13 }} />
          <Line type="monotone" dataKey="v" stroke={color} strokeWidth={1.6} dot={false} isAnimationActive={false} />
        </LineChart>
      </ResponsiveContainer>
      <p className="waveform-meta">{data.length} samples</p>
    </div>
  );
}
