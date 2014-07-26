9000 => int port;  // port to listen for osc subscribe messages
if (me.args()) me.arg(0) => Std.atoi => port;
120  => int bpm;   // beats per minute
0    => int count; // count (1 through 4) of the beat.

OscRecv recv;
port => recv.port;
recv.listen();
recv.event("/subscribe, si") @=> OscEvent subscribeEvent;
OscSend @ listeners[64];
string addies[64];

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

fun string formatAddress(string host, int port) {
    return host + "_" + Std.itoa(port);
}

fun int hasAddress(string host, int port) {
    formatAddress(host, port) => string addy;
    for (0 => int i; i < addies.size(); i++) {
        if (addies[i] == null || addies[i] == "") {
            <<< "address ", addy, " is UNKNOWN 1" >>>;
            return false;
        }
        if (addies[i] == addy) {
            <<< "address ", addy, " is KNOWN" >>>;
            return true;
        } else {
            <<< addies[i], " != ", addy >>>;
        }
    }
    <<< "address ", addy, " is UNKNOWN 2" >>>;
    return false; // I don't think we can even get here.
}

fun void addAddress(string host, int port) {
    for (0 => int i; i < addies.size(); i++) {
        if (addies[i] == null || addies[i] == "") {
            formatAddress(host, port) => addies[i];
            <<< "add address ", formatAddress(host, port), " at index ", i >>>;
            return;
        }
    }
}

fun void addListener(string host, int port) {
    if (hasAddress(host, port)) {
        <<< "already subscribed: ", host, port >>>;
        return;
    }

    for (0 => int i; i < listeners.size(); i++) {
        if (listeners[i] == null) {
            OscSend listener;
            listener.setHost(host, port);
            listener @=> listeners[i];
            addAddress(host, port);
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
