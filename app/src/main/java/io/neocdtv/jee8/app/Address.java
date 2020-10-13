package io.neocdtv.jee8.app;

import javax.persistence.*;
import java.math.BigInteger;

@Entity
@Table(name = "t_address")
public class Address {

  public static final String SEQUENCE_NAME = "sq_address";

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = SEQUENCE_NAME)
  @SequenceGenerator(name = SEQUENCE_NAME, sequenceName = SEQUENCE_NAME, allocationSize = 1)
  private BigInteger id;


  @Column(name = "city")
  private String city;

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
}
