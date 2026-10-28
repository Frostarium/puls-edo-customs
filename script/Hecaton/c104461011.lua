--Fusion of the Hundred Handed Giants
local s,id=GetID()
function s.initial_effect(c)
	--Reveal 2 "Hecahands" monsters in your hand; Fusion Summon 1 "Hecahands" Fusion Monster from your Extra Deck, using 2 monsters your opponent controls, treating them as "Hecahands" monsters
	local fusion_params={
			handler=c,
			fusfilter=function(fc) return fc:IsSetCard(SET_HECAHANDS) end,
			matfilter=aux.FALSE,
			extrafil=s.fextra,
			exactcount=2
		}
	s.fustg=Fusion.SummonEffTG(fusion_params)
	s.fusop=Fusion.SummonEffOP(fusion_params)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SET_HECAHANDS}
function s.costfilter(c)
	return c:IsSetCard(SET_HECAHANDS) and c:IsMonster() and not c:IsPublic()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,2,2,nil)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end
--The only materials are monsters your opponent controls
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(aux.AND(Card.IsMonster,Card.IsAbleToGrave),tp,0,LOCATION_MZONE,nil)
end
--Treat your opponent's monsters as "Hecahands" monsters while checking/choosing the materials
function s.addsetcode(e,tp)
	local effs={}
	for tc in Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE,nil):Iter() do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_SETCODE)
		e1:SetValue(SET_HECAHANDS)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1,true)
		table.insert(effs,e1)
	end
	return effs
end
function s.clearsetcode(effs)
	for _,e1 in ipairs(effs) do
		e1:Reset()
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local effs=s.addsetcode(e,tp)
		local res=s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
		s.clearsetcode(effs)
		return res
	end
	return s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local effs=s.addsetcode(e,tp)
	s.fusop(e,tp,eg,ep,ev,re,r,rp)
	s.clearsetcode(effs)
end
