--Tyrfing
local s,id=GetID()
local CARD_POLTRGEIST_WARRING_TRIAD=89671215
local TOKEN_MAGICITE=89671220
local SET_WARRING_TRIAD=0x1613
local CARD_STATUE_OF_THE_GODS=89671213
s.listed_names={CARD_POLTRGEIST_WARRING_TRIAD,TOKEN_MAGICITE,CARD_STATUE_OF_THE_GODS}
function s.initial_effect(c)
	--Special Summon 1 "Magicite Token" and this card (as a Level 3 EARTH Wyrm Tuner), then immediately Synchro Summon "Poltrgeist of the Warring Triad" using them, and if you do, equip this card to it from the GY
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Add 1 "Warring Triad" card from your GY to your hand
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--"Poltrgeist of the Warring Triad" can activate its effect twice per turn (see its script)
end
--Tokens + Synchro Summon + equip
function s.sycheck(c)
	--only checks that it is in the Extra Deck: it cannot be tested against the Tokens before they exist
	return c:IsCode(CARD_POLTRGEIST_WARRING_TRIAD)
end
function s.syfilter(c,mg)
	return c:IsCode(CARD_POLTRGEIST_WARRING_TRIAD) and c:IsSynchroSummonable(nil,mg)
end
--this card itself is Special Summoned as a Level 3 EARTH Wyrm Tuner Normal Monster (0/0)
function s.selfcheck(tp)
	return Duel.IsPlayerCanSpecialSummonMonster(tp,id,SET_WARRING_TRIAD,TYPE_MONSTER|TYPE_NORMAL|TYPE_TUNER,0,0,3,RACE_WYRM,ATTRIBUTE_EARTH)
end
function s.tkcheck(tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
		and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_MAGICITE,nil,TYPES_TOKEN,0,0,3,RACE_WYRM,ATTRIBUTE_EARTH)
		and s.selfcheck(tp)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:IsHasType(EFFECT_TYPE_ACTIVATE) and s.tkcheck(tp)
			and Duel.IsExistingMatchingCard(s.sycheck,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not s.tkcheck(tp) then return end
	--1 "Magicite Token": Level 3 EARTH Wyrm 0/0, set here instead of in the database
	local token=Duel.CreateToken(tp,TOKEN_MAGICITE)
	token:Level(3)
	token:Race(RACE_WYRM)
	token:Attribute(ATTRIBUTE_EARTH)
	token:Attack(0)
	token:Defense(0)
	local tg=Group.CreateGroup()
	if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP) then
		tg:AddCard(token)
	end
	--this card: Special Summoned as the Tuner that "Poltrgeist of the Warring Triad" needs
	c:AddMonsterAttribute(TYPE_NORMAL|TYPE_TUNER,ATTRIBUTE_EARTH,RACE_WYRM,3,0,0)
	if Duel.SpecialSummonStep(c,0,tp,tp,true,false,POS_FACEUP) then
		tg:AddCard(c)
	end
	c:AddMonsterAttributeComplete()
	Duel.SpecialSummonComplete()
	tg=tg:Filter(Card.IsLocation,nil,LOCATION_MZONE)
	if #tg<2 then return end
	--immediately Synchro Summon "Poltrgeist of the Warring Triad" using those 2 monsters
	local sg=Duel.GetMatchingGroup(s.syfilter,tp,LOCATION_EXTRA,0,nil,tg)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=sg:Select(tp,1,1,nil):GetFirst()
		--this card goes to the GY as material, so once Poltrgeist has actually arrived on the field it equips itself from there
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e2:SetCode(EVENT_SPSUMMON_SUCCESS)
		e2:SetLabelObject(sc)
		e2:SetCondition(s.eqcon)
		e2:SetOperation(s.eqop)
		e2:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e2,tp)
		Duel.SynchroSummon(tp,sc,nil,tg)
	end
end
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetOwner()
	local sc=e:GetLabelObject()
	return eg:IsContains(sc) and sc:IsFaceup() and sc:IsSummonType(SUMMON_TYPE_SYNCHRO)
		and c:IsLocation(LOCATION_GRAVE|LOCATION_ONFIELD) and not c:GetEquipTarget()
		and (c:IsLocation(LOCATION_SZONE) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetOwner()
	local sc=e:GetLabelObject()
	e:Reset()
	Duel.Hint(HINT_CARD,0,id)
	if Duel.Equip(tp,c,sc) then
		--Equip limit
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
function s.eqlimit(e,c)
	return c:GetControler()==e:GetOwnerPlayer() and c:IsCode(CARD_POLTRGEIST_WARRING_TRIAD)
end
--recycle
function s.thfilter(c)
	return c:IsSetCard(SET_WARRING_TRIAD) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
	--"Statue of the Gods" (tails): up to 2 cards from the Deck and/or GY instead
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	--"Statue of the Gods": if the coin toss for this activation was tails, add up to 2 cards from your Deck and/or GY instead of 1 from your GY
	local tails=e:GetHandler():GetFlagEffectLabel(CARD_STATUE_OF_THE_GODS)==Duel.GetCurrentChain()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g
	if tails then
		g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,2,nil)
	else
		g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	end
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
