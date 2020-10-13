package io.neocdtv.jee8.app;

public class JavaMethod {
  private String fieldName;
  private String fieldType;
  private String setterName;

  public JavaMethod(String fieldName, String fieldType, String setterName) {
    this.fieldName = fieldName;
    this.fieldType = fieldType;
    this.setterName = setterName;
  }

  public String getFieldName() {
    return fieldName;
  }

  public String getFieldType() {
    return fieldType;
  }

  public String getSetterName() {
    return setterName;
  }
}
