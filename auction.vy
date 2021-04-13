# Subasta abierta con vyper

# Parametros de subasta
# beneficiario recibe dinero del mayor postor

beneficiary : public(address)
auctionStart : public(uint256)
auctionEnd: public(uint256)

# Estado actual de la subasta
highestBidder: public(address)
highestBid: public(uint256)

# Se define como True al final para no permitir nuevos cambios
ended: public(bool)

# hace un seguimiento de las pujas reembolsadas
pendingReturns: public(HashMap[address, uint256])

""" Crea una subasta con _auction_start and bidding_time (segundos)
de parte de la direccion befeciaria
 """

@external
def __init__(_beneficiary:address, _auction_start:uint256,_bidding_time:uint256):
    self.beneficiary = _beneficiary
    self.auctionStart = _auction_start
    self.auctionEnd = self.auctionStart + _bidding_time
    assert block.timestamp < self.auctionEnd #auctionEnd sera en el futuro

""" 
Puja en la subasta enviando el valor con esta transaccion.
el valor solo sera devuelto si la subasta no se gana.
"""

@external
@payable
def bid():
    """ bid checa si la subasta ya empezo, termino o si la puja es lo suficientemente alta """
    assert block.timestamp >= self.auctionStart

    assert block.timestamp < self.auctionEnd

    assert msg.value > self.highestBid
    # Sigue el reembolso para la anterior puja
    self.pendingReturns[self.highestBidder] += self.highestBid

    self.highestBidder = msg.sender
    self.highestBid = msg.value

""" retirar una puja reembolsada anteriormente.
    El patron de retiro se usa aqui para evitar un problema de seguridad
    Si los reembolsos se mandaran directamente como parte de bid(), un contrato de puja malicio
    podria bloquear esos reembolsos y bloquear pujas mayores de entrar a la subasta
 """
@external
def withdraw():
    """ Es buena practica estructurar funciones para interactuar con otros contratos en 3 fases
    1. checar condiciones
    2. realizar acciones
    3. interacting with other contracts
    Si estas fases se juntan, el otro contrato puede llamar de vuelta el contrato y modificar el estado
    o causar que las acciones se ejecuten multiples veces(pagos de ether) """
    # checar condiciones
    assert block.timestamp >= self.auctionEnd
    assert not self.ended
    #2 Effects
    self.ended = True
    #3. Interaction
    send(self.beneficiary, self.highestBid)