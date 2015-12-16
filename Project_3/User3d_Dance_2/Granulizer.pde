class Granulizer extends UGen
{
  public UGenInput grainSize;
  public UGenInput grainRepeat;
  
  MultiChannelBuffer sampleData;
  int                grainStart;
  int                sampleCount;
  int                sampleLoopCount;
  
  Granulizer( MultiChannelBuffer sourceSample, int grainSizeInSamples )
  {
    grainSize = new UGenInput( InputType.CONTROL );
    grainSize.setLastValue( grainSizeInSamples );
    
    grainRepeat = new UGenInput( InputType.CONTROL );
    grainRepeat.setLastValue( 16 );
    
    sampleData = sourceSample;
  }
  
  protected void uGenerate( float[] out )
  {
    int gsize = (int)grainSize.getLastValue();
    if ( sampleCount >= gsize )
    {
      sampleCount = 0;
      ++sampleLoopCount;
      if ( sampleLoopCount >= (int)grainRepeat.getLastValue() )
      {
        grainStart = int( random( 0, sampleData.getBufferSize() - gsize ) );
        sampleLoopCount = 0;
      }
    }
    
    for( int c = 0; c < out.length; ++c )
    {
      int   sourceChannel = c < sampleData.getChannelCount() ? c : sampleData.getChannelCount() - 1;
      int   sample = grainStart + sampleCount;
      if ( sample >= sampleData.getBufferSize() ) sample -= sampleData.getBufferSize();
      out[c] = sampleData.getSample( sourceChannel, sample );
    }
    
    ++sampleCount;
  }
}
