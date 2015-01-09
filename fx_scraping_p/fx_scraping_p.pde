import processing.serial.*;
import java.io.*;
import java.net.URL;
import java.net.URLConnection;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.StringTokenizer;

import processing.serial.*;

int interval = 10; // retrieve feed every 60 seconds;
int lastTime;      // the last time we fetched the content

int light = 0; // light level measured by the lamp

Serial port;
color c;
String cs;

String doll;
String doll_old;

String buffer = ""; // Accumulates characters coming from Arduino

PFont font;

void setup() {
  size(640, 480);
  frameRate(10); // we don't need fast updates

  font = loadFont("HelveticaNeue-Bold-32.vlw");
  fill(255);
  textFont(font, 32);

  // IMPORTANT NOTE:
  // The first serial port retrieved by Serial.list()
  // should be your Arduino. If not, uncomment the next
  // line by deleting the // before it, and re-run the
  // sketch to see a list of serial ports. Then, change
  // the 0 in between [ and ] to the number of the port
  // that your Arduino is connected to.
  //println(Serial.list());
  String arduinoPort = Serial.list()[0];

  port = new Serial(this, arduinoPort, 9600); // connect to Arduino
  lastTime = 0;
  fetchData();
}

void draw() {
  background( c );
  int n = (interval - ((millis()-lastTime)/1000));
  int up=0;
  int stay=0;
  int down=0;

  if(Float.parseFloat(doll) > Float.parseFloat(doll_old)){
     up = 255;
  }else if(Float.parseFloat(doll) < Float.parseFloat(doll_old)){
     down = 255;
  }else{
     stay = 255;
  }

  // Build a colour based on the 3 values
  c = color(up, stay, down);
  cs = "#" + hex(c, 6); // Prepare a string to be sent to Arduino

  text("Arduino Networked Lamp", 10, 40);
  text("Reading $doll:", 10, 100);
  text(doll, 10, 140);

  text("Next update in "+ n + " seconds", 10, 450);

  text("up", 10, 200);
  text(" " + up, 130, 200);
  rect(200, 172, up, 28);

  text("down ", 10, 240);
  text(" " + down, 130, 240);
  rect(200, 212, down, 28);

  text("stay ", 10, 280);
  text(" " + stay, 130, 280);
  rect(200, 252, stay, 28);

  // write the colour string to the screen
  text("sending", 10, 340);
  text(cs, 200, 340);
  text("light level", 10, 380);
  rect(200, 352, light/10.23, 28); // this turns 1023 into 100

  if (n <= 0) {
    fetchData();
    lastTime = millis();
  }

  port.write(cs); // send data to Arduino

  if (port.available() > 0) { // check if there is data waiting
    int inByte = port.read(); // read one byte
    if (inByte != 10) { // if byte is not newline
      buffer = buffer + char(inByte); // just add it to the buffer
    }
    else {

      // newline reached, let's process the data
      if (buffer.length() > 1) { // make sure there is enough data

        // chop off the last character, it's a carriage return
        // (a carriage return is the character at the end of a
        // line of text)
        buffer = buffer.substring(0, buffer.length() -1);

        // turn the buffer from string into an integer number
        light = int(buffer);

        // clean the buffer for the next read cycle
        buffer = "";

        // We're likely falling behind in taking readings
        // from Arduino. So let's clear the backlog of
        // incoming sensor readings so the next reading is
        // up-to-date.
        port.clear();
      }
    }
  }
}

void fetchData() {
  try {
		doll_old = doll;

	   // Get all the HTML/XML source code into an array of strings
	    // (each line is one element in the array)
	    String url = "http://info.finance.yahoo.co.jp/fx/detail/?code=USDJPY=FX";
	    String[] lines = loadStrings(url);
	    
	    // Turn array into one long String
	    String xml = join(lines, "" ); 
	    
	    String lookfor = "<dd id=\"USDJPY_detail_bid\">";
	    String end = "</span>";
	    doll = giveMeTextBetween(xml,lookfor,end);
	    doll = doll.replace("<span class=\"large\">", "");
		if(doll_old==null)
			doll_old = doll;

	    System.out.println(doll);

	} catch(Exception e){
	    e.printStackTrace();
        System.out.println("ERROR: "+e.getMessage());
	}
}

// A function that returns a substring between two substrings
String giveMeTextBetween(String s, String before, String after) {
	String found = "";
	int start = s.indexOf(before);    // Find the index of the beginning tag
	if (start == - 1) return"";       // If we don't find anything, send back a blank String
	start += before.length();         // Move to the end of the beginning tag
	int end = s.indexOf(after,start); // Find the index of the end tag
	if (end == -1) return"";          // If we don't find the end tag, send back a blank String
	return s.substring(start,end);    // Return the text in between
}
