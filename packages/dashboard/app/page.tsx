'use client';

import { useState } from 'react';
import ScoreCard from '../components/ScoreCard';

interface BreakdownItem {
  label: string;
  value: number;
  max: number;
}

interface ScoreResponse {
  address: string;
  score: number;
  tier: 'gold' | 'silver' | 'unknown';
  breakdown: BreakdownItem[];
  error?: string;
}

export default function Home() {
  const [address, setAddress] = useState('');
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<ScoreResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchScore = async (addrToFetch: string) => {
    if (!addrToFetch || !addrToFetch.startsWith('0x')) {
      setError('Please enter a valid Ethereum address starting with 0x');
      return;
    }
    
    setLoading(true);
    setError(null);
    setData(null);
    setAddress(addrToFetch); // Update input field if clicked from examples
    
    try {
      const res = await fetch(`/api/score?address=${addrToFetch}`);
      const result = await res.json();
      
      if (!res.ok) {
        throw new Error(result.error || 'Failed to fetch score');
      }
      
      setData(result);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'An error occurred while fetching the score');
    } finally {
      setLoading(false);
    }
  };

  const handleExampleClick = (addr: string) => {
    fetchScore(addr);
  };

  return (
    <main className="max-w-4xl mx-auto py-12 px-6">
      <div className="text-center mb-12">
        <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-blue-400 to-indigo-500 text-transparent bg-clip-text">
          AgentCredit Protocol
        </h1>
        <p className="text-xl text-gray-400">On-chain credit bureau for AI agents</p>
      </div>

      <div className="bg-gray-900 border border-gray-800 rounded-xl p-8 shadow-xl max-w-2xl mx-auto mb-12">
        <form 
          onSubmit={(e) => { e.preventDefault(); fetchScore(address); }}
          className="flex flex-col sm:flex-row gap-4"
        >
          <input
            type="text"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="0x... agent address"
            className="flex-grow bg-gray-950 border border-gray-700 rounded-lg px-4 py-3 text-gray-100 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 font-mono"
          />
          <button
            type="submit"
            disabled={loading}
            className="bg-blue-600 hover:bg-blue-500 text-white px-8 py-3 rounded-lg font-medium transition-colors disabled:opacity-50"
          >
            {loading ? 'Checking...' : 'Check Score'}
          </button>
        </form>

        <div className="mt-8">
          <p className="text-sm text-gray-500 mb-3 uppercase tracking-wider font-semibold">Quick Examples</p>
          <div className="flex flex-wrap gap-3">
            <button 
              onClick={() => handleExampleClick('0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa')}
              className="bg-gray-800 hover:bg-gray-700 border border-gray-700 rounded-lg px-4 py-2 text-sm text-gray-300 transition-colors font-mono"
            >
              Agent A (~520)
            </button>
            <button 
              onClick={() => handleExampleClick('0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB')}
              className="bg-gray-800 hover:bg-gray-700 border border-gray-700 rounded-lg px-4 py-2 text-sm text-gray-300 transition-colors font-mono"
            >
              Agent B (~680)
            </button>
            <button 
              onClick={() => handleExampleClick('0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC')}
              className="bg-gray-800 hover:bg-gray-700 border border-gray-700 rounded-lg px-4 py-2 text-sm text-gray-300 transition-colors font-mono"
            >
              Agent C (~820)
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="bg-red-900/50 border border-red-800 text-red-200 px-6 py-4 rounded-lg mb-8 max-w-2xl mx-auto">
          {error}
        </div>
      )}

      {data && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-start">
          <ScoreCard score={data.score} tier={data.tier} address={data.address} />
          
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 shadow-xl">
            <h3 className="text-lg font-semibold text-gray-200 mb-6 border-b border-gray-800 pb-2">Score Breakdown</h3>
            <div className="space-y-5">
              {data.breakdown.map((item, i) => {
                const percent = Math.min(100, Math.max(0, (item.value / item.max) * 100));
                return (
                  <div key={i}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-gray-400">{item.label}</span>
                      <span className="text-gray-200 font-medium">+{item.value} <span className="text-gray-600">/ {item.max}</span></span>
                    </div>
                    <div className="w-full bg-gray-800 rounded-full h-2">
                      <div
                        className="bg-blue-500 h-2 rounded-full transition-all duration-1000 ease-out"
                        style={{ width: `${percent}%` }}
                      ></div>
                    </div>
                  </div>
                );
              })}
            </div>
            <div className="mt-6 pt-4 border-t border-gray-800 text-xs text-gray-500 text-center">
              Base score is 300. Max score is 900.
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
