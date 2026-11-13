object Animal
object Dog extends Animal
object Lista[+A](val item: A)

method main {
  val l: Lista[Dog] = new Lista[Animal](new Animal)
}
