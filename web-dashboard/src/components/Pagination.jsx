export default function Pagination({ page, totalPages, total, onChange }) {
  if (!total) return null;
  return (
    <div className="pagination">
      <span>{total} total &middot; page {page} of {Math.max(totalPages, 1)}</span>
      <div className="pagination-controls">
        <button className="btn btn-ghost btn-sm" disabled={page <= 1} onClick={() => onChange(page - 1)}>
          Previous
        </button>
        <button className="btn btn-ghost btn-sm" disabled={page >= totalPages} onClick={() => onChange(page + 1)}>
          Next
        </button>
      </div>
    </div>
  );
}
