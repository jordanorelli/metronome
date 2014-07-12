9000 => port;      // port to listen for osc subscribe messages
120  => int bpm;   // beats per minute
0    => int count; // count (1 through 4) of the beat.

OscRecv recv;
port => recv.port;
recv.listen();
recv.event("/subscribe, si") @=> OscEvent subscribeEvent;
OscSend @ listeners[64]; OscSend send;

fun void subscribe() {
    while (true) {
        subscribeEvent => now;
        while (subscribeEvent.nextMsg() != 0) {
            subscribeEvent.getString() => string host;
            subscribeEvent.getInt() => int port;
            addListener(host, port);
            <<< "subscribe", host, port >>>;
        }
    }
}
spork ~ subscribe();

fun void addListener(string host, int port) {
    for (0 => int i; i < listeners.size(); i++) {
        if (listeners[i] == null) {
            OscSend listener;
            listener.setHost(host, port);
            listener @=> listeners[i];
            return;
        }
    }
}

fun void sendBeat(int count) {
    for (0 => int i; i < listeners.size(); i++) {
        if (listeners[i] != null) {
            listeners[i].startMsg("/down, i");
            listeners[i].addInt(count);
        }
    }
}

while (true) {
    sendBeat(count+1);
    1 +=> count;
    if (count % 4 == 0) {
        0 => count;
    }
    1::minute / bpm => now;
}
