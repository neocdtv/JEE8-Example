package io.neocdtv.jee8.app.entity;

import javax.persistence.*;

@Entity
@Table(name = "t_flat")
public class Flat {

  public static final String SEQUENCE_NAME = "sq_flat";

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = SEQUENCE_NAME)
  @SequenceGenerator(name = SEQUENCE_NAME, sequenceName = SEQUENCE_NAME, initialValue = 10, allocationSize = 10)

  @Column(name = "size")
  private Integer size;

  @OneToOne(mappedBy = "flat")
  public Address address;

  public Integer getSize() {
    return size;
  }

  public void setSize(Integer size) {
    this.size = size;
  }

  public Address getAddress() {
    return address;
  }

  public void setAddress(Address address) {
    this.address = address;
  }
}
