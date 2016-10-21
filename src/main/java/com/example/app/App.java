package com.example.app;

import net.conjur.api.Conjur;

public class App {
  public static void main( String[] args ) {
    // Create API object from configuration file
    Conjur conjurApi = new ConjurBuilder()
      .configurationPath("/etc/conjur.conf")
      .build();
    
    // As proof of concept, we'll print out some variable values from Conjur
    System.out.println("Hello World! Here are some example values:");
    System.out.println(conjurApi.variables().get("app/password1").getValue());
    System.out.println(conjurApi.variables().get("app/password2").getValue());
  }
}
