package io.neocdtv.jee8.app;

public class PersonBuilder {

  private Person person = new Person();

  public static PersonBuilder create() {
    return new PersonBuilder();
  }

  public PersonBuilder id(java.math.BigInteger id) {
    person.setId(id);
    return this;
  }

  public PersonBuilder firstName(java.lang.String firstName) {
    person.setFirstName(firstName);
    return this;
  }

  public PersonBuilder lastName(java.lang.String lastName) {
    person.setLastName(lastName);
    return this;
  }

  public Person get() {
    return person;
  }
}
