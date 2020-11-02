package io.neocdtv.jee8.app.entity;

import javax.persistence.*;
import java.math.BigInteger;

@Entity
@Table(name = "t_organisation")
public class Organisation {

  public static final String SEQUENCE_NAME = "sq_orgranisation";

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = SEQUENCE_NAME)
  @SequenceGenerator(name = SEQUENCE_NAME, sequenceName = SEQUENCE_NAME, initialValue = 10, allocationSize = 10)
  private BigInteger id;

  @Column(name = "name")
  private String name;

  public BigInteger getId() {
    return id;
  }

  public void setId(BigInteger id) {
    this.id = id;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }
}
