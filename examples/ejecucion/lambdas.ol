method main {
  val inc = (x: Int) => x + 1
  val suma = (a: Int, b: Int) => a + b
  val doble = (n: Int) => {
    println("doblando $n")
    n * 2
  }
  println(inc(1))
  println(suma(2, 3))
  println(doble(21))
}
