export default function Spinner({ label = 'Loading…' }: { label?: string }) {
  return (
    <div className="spinner-wrap">
      <div className="spinner-ring">
        <div /><div /><div /><div />
      </div>
      <span className="spinner-label">{label}</span>
      <style jsx>{`
        .spinner-wrap {
          display: flex; flex-direction: column; align-items: center;
          justify-content: center; gap: 16px; padding: 64px;
        }
        .spinner-ring {
          display: inline-block; position: relative; width: 48px; height: 48px;
        }
        .spinner-ring div {
          box-sizing: border-box; display: block; position: absolute;
          width: 40px; height: 40px; margin: 4px;
          border: 4px solid transparent;
          border-top-color: #22c55e;
          border-radius: 50%;
          animation: spin 1s cubic-bezier(0.5, 0, 0.5, 1) infinite;
        }
        .spinner-ring div:nth-child(1) { animation-delay: -0.3s; }
        .spinner-ring div:nth-child(2) { animation-delay: -0.2s; }
        .spinner-ring div:nth-child(3) { animation-delay: -0.1s; }
        @keyframes spin {
          0%   { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .spinner-label {
          font-size: 14px; font-weight: 600; color: #888; letter-spacing: 0.3px;
        }
      `}</style>
    </div>
  );
}
