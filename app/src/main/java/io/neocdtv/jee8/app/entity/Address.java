package io.neocdtv.jee8.app.entity;

import javax.persistence.*;
import java.math.BigInteger;

@Entity
@Table(name = "t_address")
public class Address {

  public static final String SEQUENCE_NAME = "sq_address";

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = SEQUENCE_NAME)
  @SequenceGenerator(name = SEQUENCE_NAME, sequenceName = SEQUENCE_NAME, initialValue = 10, allocationSize = 10)
  private BigInteger id;

  @Column(name = "city")
  private String city;

  @ManyToOne(fetch = FetchType.LAZY)
  private Person person;

  @OneToOne
  @JoinColumn(name = "flat_id", referencedColumnName = "id")
  private Flat flat;

  public BigInteger getId() {
    return id;
  }

  public void setId(BigInteger id) {
    this.id = id;
  }

  public String getCity() {
    return city;
  }

  public void setCity(String city) {
    this.city = city;
  }

  public Person getPerson() {
    return person;
  }

  public void setPerson(Person person) {
    this.person = person;
  }

  public Flat getFlat() {
    return flat;
  }

  public void setFlat(Flat flat) {
    this.flat = flat;
  }
}
