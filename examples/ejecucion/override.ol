object Saludo
Saludo.decir = method(nombre: String): String

method main {
  val s: Saludo = new Saludo {
    override decir(nombre: String): String = {
      "hola $nombre"
    }
  }
  println(s.decir("mundo"))
}
