import { NextRequest, NextResponse } from 'next/server';
import { getAgentScore } from '../../../lib/registry';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const address = searchParams.get('address');

  if (!address || !address.startsWith('0x')) {
    return NextResponse.json({ error: 'Invalid address provided' }, { status: 400 });
  }

  try {
    const { score, tier } = await getAgentScore(address);
    
    // The base score is 300. The remaining points (up to 600) are distributed among 4 categories.
    // Since the smart contract doesn't expose the individual components, we estimate them for the dashboard breakdown.
    const pointsAboveBase = Math.max(0, score - 300);
    const fraction = pointsAboveBase / 600;

    const breakdown = [
      { label: 'Payment History', value: Math.round(270 * fraction), max: 270 },
      { label: 'Volume Score', value: Math.round(180 * fraction), max: 180 },
      { label: 'Account Age', value: Math.round(150 * fraction), max: 150 },
      { label: 'Payment Velocity', value: Math.round(70 * fraction), max: 70 },
    ];

    // Adjust the last value to ensure the sum matches exactly if there's rounding error
    const currentSum = breakdown.reduce((acc, curr) => acc + curr.value, 0);
    if (currentSum !== pointsAboveBase) {
      breakdown[0].value += (pointsAboveBase - currentSum);
    }

    return NextResponse.json({
      address,
      score,
      tier,
      breakdown,
    });
  } catch (error) {
    console.error('API Error:', error);
    return NextResponse.json({ error: 'Failed to fetch score' }, { status: 500 });
  }
}
