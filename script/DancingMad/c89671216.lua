--Fiend of the Warring Triad
local s,id,o=GetID()
local CARD_STATUE_OF_THE_GODS=89671213
s.listed_names={CARD_STATUE_OF_THE_GODS}
function s.initial_effect(c)
	--Xyz Summon procedure: 2 Level 6 Fiend monsters
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND),6,2)
	--Special Summon a Spell/Trap as a monster with the stats of a monster, and turn that monster into a Continuous Spell/Trap
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.mfilter(c)
	return c:IsFaceup() and c:IsMonster()
end
function s.stfilter(c)
	return c:IsFaceup() and c:IsSpellTrap()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp) and chkc:IsOnField() and (s.mfilter(chkc) or s.stfilter(chkc))
	end
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.mfilter,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(s.stfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g1=Duel.SelectTarget(tp,s.mfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g2=Duel.SelectTarget(tp,s.stfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g2,1,1-tp,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetTargetCards(e)
	local mc=tg:Filter(Card.IsMonster,nil):GetFirst()
	local sc=tg:Filter(Card.IsSpellTrap,nil):GetFirst()
	if not (mc and sc and s.mfilter(mc) and s.stfilter(sc)) then return end
	--"Statue of the Gods": if the coin toss was tails, summon it to your field and place the monster in your Spell & Trap Zone instead
	local dest=1-tp
	if c:GetFlagEffectLabel(CARD_STATUE_OF_THE_GODS)==Duel.GetCurrentChain()
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		dest=tp
	end
	if Duel.GetLocationCount(dest,LOCATION_MZONE)<=0 then return end
	--the monster needs a Spell & Trap Zone to go to (on your opponent's side the Spell/Trap frees its own, unless it is in the Field Zone)
	if dest==1-tp and sc:IsLocation(LOCATION_FZONE) and Duel.GetLocationCount(1-tp,LOCATION_SZONE)<=0 then return end
	--the Spell/Trap's new stats are those of the monster
	local level=mc:GetLevel()
	if level<=0 then level=mc:GetRank() end
	if level<=0 then level=1 end
	local ctype=sc:IsSpell() and TYPE_SPELL or TYPE_TRAP
	sc:AddMonsterAttribute(TYPE_EFFECT|ctype,mc:GetAttribute(),mc:GetRace(),level,mc:GetAttack(),mc:GetDefense())
	local summoned=Duel.SpecialSummonStep(sc,0,tp,dest,true,false,POS_FACEUP_ATTACK)
	if summoned then sc:AddMonsterAttributeComplete() end
	Duel.SpecialSummonComplete()
	if not (summoned and sc:IsLocation(LOCATION_MZONE)) then return end
	--the monster is placed in the Spell & Trap Zone as a Continuous Spell/Trap (same type as the Spell/Trap)
	Duel.BreakEffect()
	if mc:IsRelateToEffect(e) and mc:IsFaceup()
		and Duel.MoveToField(mc,tp,dest,LOCATION_SZONE,POS_FACEUP,true) and mc:IsLocation(LOCATION_SZONE) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(ctype|TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
		mc:RegisterEffect(e1)
		if dest==tp then
			--Destroy this card; draw 2 cards
			local e2=Effect.CreateEffect(c)
			e2:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
			e2:SetType(EFFECT_TYPE_IGNITION)
			e2:SetRange(LOCATION_SZONE)
			e2:SetTarget(s.drtg)
			e2:SetOperation(s.drop)
			e2:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TURN_SET))
			mc:RegisterEffect(e2)
		end
	end
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.Destroy(c,REASON_EFFECT)>0 then
		Duel.Draw(tp,2,REASON_EFFECT)
	end
end
