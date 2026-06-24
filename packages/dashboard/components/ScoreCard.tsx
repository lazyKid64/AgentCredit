'use client';

interface ScoreCardProps {
  score: number;
  tier: 'gold' | 'silver' | 'unknown';
  address: string;
}

export default function ScoreCard({ score, tier, address }: ScoreCardProps) {
  const truncatedAddress = `${address.slice(0, 6)}...${address.slice(-4)}`;

  let scoreColor = 'text-red-400';
  let barColor = 'bg-red-400';
  if (score >= 750) {
    scoreColor = 'text-green-400';
    barColor = 'bg-green-400';
  } else if (score >= 600) {
    scoreColor = 'text-yellow-400';
    barColor = 'bg-yellow-400';
  }

  let badgeClass = 'bg-gray-800 text-gray-400';
  let badgeText = '⬜ Unknown';
  if (tier === 'gold') {
    badgeClass = 'bg-yellow-900 text-yellow-200';
    badgeText = '🥇 Gold';
  } else if (tier === 'silver') {
    badgeClass = 'bg-gray-700 text-gray-200';
    badgeText = '🥈 Silver';
  }

  const progressPercent = Math.max(0, Math.min(100, ((score - 300) / 600) * 100));

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 shadow-xl w-full max-w-md mx-auto">
      <div className="flex justify-between items-center mb-6">
        <span className="text-gray-400 font-mono text-sm">{truncatedAddress}</span>
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${badgeClass}`}>
          {badgeText}
        </span>
      </div>

      <div className="text-center mb-6">
        <div className={`text-6xl font-bold ${scoreColor}`}>
          {score}
        </div>
        <div className="text-gray-500 text-sm mt-2 uppercase tracking-widest">
          Agent Credit Score
        </div>
      </div>

      <div className="w-full bg-gray-800 rounded-full h-3 mb-2">
        <div
          className={`h-3 rounded-full ${barColor} transition-all duration-1000 ease-out`}
          style={{ width: `${progressPercent}%` }}
        ></div>
      </div>
      <div className="flex justify-between text-xs text-gray-500 font-mono">
        <span>300</span>
        <span>900</span>
      </div>
    </div>
  );
}
