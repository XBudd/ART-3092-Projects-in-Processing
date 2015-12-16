// a class that will sample and then repeat a section of incoming audio
// while it continues to tick the audio coming into it.
// it is a similar effect to Live's BeatRepeat
public class SampleRepeat extends UGen
{
  UGenInput filePlayer = new UGenInput(InputType.AUDIO);
  
  // the buffer of audio we will record into and then repeat
  private float[] m_buffer;
  // how long is our sample buffer
  private int m_sampleLength;
  // where are we recording/playing back in our buffer?
  private int m_currSample;
  
  private float m_tempo;
  private float m_sampleLengthInBeats;
  
  private static final int PASS = -1;
  private static final int SAMPLE = 0;
  private static final int REPEAT = 1;
  
  private int m_state;
  
  public SampleRepeat( float tempo, float sampleLengthInBeats )
  {
    m_buffer = null;
    m_tempo = tempo;
    m_sampleLengthInBeats = sampleLengthInBeats;
    m_state = PASS;
  }
  
  void setSampleLength( float tempo, float sampleLengthInBeats )
  {
    m_tempo = tempo;
    m_sampleLengthInBeats = sampleLengthInBeats;
    float beatPerSec = 60.f / tempo;
    m_sampleLength = int(sampleLengthInBeats * sampleRate() * beatPerSec);
  }
  
  void sampleRateChanged()
  {
    setSampleLength( m_tempo, m_sampleLengthInBeats );
  }
  
  boolean isActive() 
  {
    return ( m_state != PASS );
  }
  
  void activate()
  {
    m_state = SAMPLE;
    m_currSample = 0;
  }
  
  void deactivate()
  {
    m_state = PASS;
  }
  
  void uGenerate( float[] channels )
  {
    // reinitialize buffer if things change
    if ( m_buffer == null || m_buffer.length != m_sampleLength * channels.length )
    {
      m_buffer = new float[ m_sampleLength * channels.length ];
    }
        
    switch( m_state )
    {
    case PASS:
      {
        arraycopy( filePlayer.getLastValues(), channels );
      }
      break;
      
    case SAMPLE:
      {
        // pass the audio
        arraycopy( filePlayer.getLastValues(), channels );
        // but also record it
        int offset = m_currSample * channels.length;
        arraycopy( channels, 0, m_buffer, offset, channels.length );
        float fadeIn = constrain( map( m_currSample, 0, 128, 0, 1 ), 0, 1 );
        float fadeOut = constrain( map( m_currSample, m_sampleLength - 128, m_sampleLength, 1, 0 ), 0, 1 );
        for(int i = offset; i < offset + channels.length; i++)
        {
          m_buffer[i] *= fadeIn;
          m_buffer[i] *= fadeOut;
        }
        
        m_currSample++;
        if ( m_currSample == m_sampleLength )
        {
          m_state = REPEAT;
          m_currSample = 0;
        }
      }
      break;
      
    case REPEAT:
      {
        arraycopy( m_buffer, m_currSample * channels.length, channels, 0, channels.length );
        m_currSample = ( m_currSample + 1 ) % m_sampleLength;
      }
      break;
    }
  }
}
