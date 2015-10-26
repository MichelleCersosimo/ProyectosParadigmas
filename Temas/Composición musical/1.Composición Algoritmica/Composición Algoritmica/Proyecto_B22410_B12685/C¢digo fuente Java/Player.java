
import javax.sound.midi.*;

/**
 *
 * @author Esquivel Oscar
 * @author Garbanzo Diana
 */
public class Player
{
    Track track;
    Sequence sequence;
    Sequencer sequencer;
    long ticks;
    boolean chords;
    
    final int NOTEON = 144;
    final int NOTEOFF = 128;
    final int PROGRAM = 192;

    /**
     * Constructor for objects of class Player
     */
    public Player()
    {
        ticks = 0;
        try
        {
            sequencer = MidiSystem.getSequencer();
            sequence = new Sequence(Sequence.PPQ, 10);
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
            return; 
        }
    }

    /**
     * Dados 60 bpm:
     * 60 bpm / 60 segundos-por-minuto = 1 beat por segundo
     * Resolución = 10
     * 10 ticks por beat
     */
    public void createShortEvent(int type, int note)
    {
        ShortMessage message = new ShortMessage();
        try
        {
            message.setMessage(type, note, 64);
            MidiEvent event = new MidiEvent(message, ticks);
            track.add(event);
            if(chords)
            {
                ShortMessage chordMessage = new ShortMessage();
                chordMessage.setMessage(type, note+7, 64); //power chord
                MidiEvent chordEvent = new MidiEvent(chordMessage, ticks); //mismo momento
                track.add(chordEvent);
            }
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
        }
    }

    /**
     * Recibe un arreglo de números que representan las notas por tocar, los sonidos y las duraciones.
     */
    public void playMusic(String[] notasYduraciones)
    {
        track = sequence.createTrack();
        try
        {
            // 25 Nylon-str.Gt
            // 26 Steel-str.Gt
            // 27 Jazz Gt.    
            // 28 Clean Gt.   
            // 29 Muted Gt.   
            // 30 Overdrive Gt
            // 31 DistortionGt
            // 32 Gt.Harmonics
            createShortEvent(PROGRAM, 30);
            for(int i=0; i<notasYduraciones.length && notasYduraciones[i]!=null; i+=2)
            {
                if(Integer.parseInt(notasYduraciones[i]) < 0 && Double.parseDouble(notasYduraciones[i+1]) < 0.0) //divisor
                {
                    chords = true;
                    continue;
                }
                //Se inicia el evento de la nota
                createShortEvent(NOTEON, Integer.parseInt(notasYduraciones[i]));
                //Se suma la nueva duración en ticks, y eso da el tick para el siguiente beat
                ticks += Double.parseDouble(notasYduraciones[i+1]) * sequence.getResolution(); //Resolution: 10
                //System.out.println(ticks);
                //Se termina el evento de la nota
                createShortEvent(NOTEOFF, Integer.parseInt(notasYduraciones[i]));
            }
            createShortEvent(NOTEON, 0);
            ticks += 4;
            createShortEvent(NOTEOFF, 0);
            ticks += 4;
            
            //prueba de agregar un metrónomo a la canción
            // 115 Steel Drums
            Track trackMetronome = sequence.createTrack();
            long ticks2 = ticks;
            ticks = 0;
            for(int i=0; i<ticks2; i+=10)
            {
                ShortMessage messageON = new ShortMessage();
                ShortMessage messageOFF = new ShortMessage();
                try
                {
                    messageON.setMessage(NOTEON, 40, 64);
                    MidiEvent eventON = new MidiEvent(messageON, ticks);
                    trackMetronome.add(eventON);
                    messageOFF.setMessage(NOTEOFF, 40, 64);
                    MidiEvent eventOFF = new MidiEvent(messageOFF, ticks+1);
                    trackMetronome.add(eventOFF);
                    ticks += 10;
                }
                catch (Exception ex)
                {
                    ex.printStackTrace();
                }
            }
        }
        catch (Exception ex)
        {
             ex.printStackTrace();
        }
        try
        {
            sequencer.setSequence(sequence);
        }
        catch (InvalidMidiDataException ex)
        {
            ex.printStackTrace();
        }
                MidiDevice device = sequencer;
        try
        {
            device.open();
                //Synthesizer synthesizer = MidiSystem.getSynthesizer();
                //synthesizer.open();
                //Instrument instruments[];
                //instruments = synthesizer.getDefaultSoundbank().getInstruments();
                //for(int i=0; i<instruments.length; ++i)
                //{
                //    System.out.println(instruments[i].getName());
                //}
        }
        catch (MidiUnavailableException ex)
        {
            ex.printStackTrace();
        }
        sequencer.setTempoInBPM(80);
        //sequencer.setLoopEndPoint(sequencer.getSequence().getTickLength());
        sequencer.start();
        
        while(sequencer.isRunning())
        {
            if(sequencer.getTickPosition() >= ticks) //se llegó al final
            {
                sequencer.stop();
            }
        }

        if (sequencer != null)
        {
            sequencer.close();
        }
        sequencer = null;
    }
}
