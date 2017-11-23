import { Main } from '../elm/Main.elm'

const node = document.getElementById('main')


const app = Main.embed(node)

app.ports.output
  .subscribe(function(val){
    console.log("Hello from elm")
    console.log("----------------")
    console.log(val)
    console.log("----------------")
    const res = [val]
    return app.ports.incoming.send(res)
})

setTimeout( () => app.ports.incoming.send([{score: 1, total: 5, percent: 20.0 }]), 1000)


