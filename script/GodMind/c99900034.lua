--GodMind Assimilation
--Normal Trap. You can activate this card the turn it was Set by sending 1 "GodMind" monster from your Deck to the GY.
--Place 1 "GodMind Processor 10²" Pendulum Monster from your Extra Deck in your Pendulum Zone.
--If this card is in your GY: You can banish this card; Fusion Summon 1 "GodMind" Fusion Monster from your Extra Deck, using monsters from your hand
--or field, and/or "GodMind" monsters you have banished (those are shuffled into the Deck instead of being sent to the GY).
--You can only use each effect of "GodMind Assimilation" once per turn.
local s,id=GetID()
local SET_GODMIND=0x1650
local SET_PROCESSOR=0x3650
function s.initial_effect(c)
	--Activate: place a Processor Pendulum Monster from the Extra Deck in your Pendulum Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Can be activated the turn it was Set (the cost in s.cost is only paid then)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	c:RegisterEffect(e2)
	--GY: banish this card; Fusion Summon a "GodMind" Fusion Monster (materials: hand / field, or banished "GodMind" monsters shuffled into the Deck)
	local e3=Fusion.CreateSummonEff(c,s.fusfilter,nil,s.fextra,s.fop,nil,nil,nil,nil,nil,nil,aux.Stringid(id,1),nil,nil,s.extratg)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCode(0)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(Cost.SelfBanish)
	c:RegisterEffect(e3)
end
--cost: only on the turn it was Set, send 1 "GodMind" monster from your Deck to the GY
function s.costfilter(c)
	return c:IsMonster() and c:IsSetCard(SET_GODMIND) and c:IsAbleToGraveAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local pay=e:GetHandler():IsStatus(STATUS_SET_TURN)
	if chk==0 then return not pay or Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_DECK,0,1,nil) end
	if pay then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_DECK,0,1,1,nil)
		Duel.SendtoGrave(g,REASON_COST)
	end
end
function s.pzfilter(c)
	return c:IsSetCard(SET_PROCESSOR) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) and Duel.IsExistingMatchingCard(s.pzfilter,tp,LOCATION_EXTRA,0,1,nil) end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.CheckPendulumZones(tp) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.pzfilter,tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
--GY effect. (Processors have the "GodMind" archetype too; the helper itself checks that the monster is a Fusion Monster.)
function s.fusfilter(c)
	return c:IsSetCard(SET_GODMIND)
end
--extra materials: your banished face-up "GodMind" monsters
function s.rmfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsSetCard(SET_GODMIND) and c:IsAbleToDeck()
end
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_REMOVED,0,nil)
end
--the banished materials are shuffled into the Deck; the rest of the group is left for the usual "send to the GY"
function s.fop(e,tc,tp,mat)
	local rg=mat:Filter(Card.IsLocation,nil,LOCATION_REMOVED)
	if #rg>0 then
		Duel.SendtoDeck(rg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT|REASON_MATERIAL|REASON_FUSION)
		mat:Sub(rg)
	end
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_REMOVED)
end
