--D.J. NG-L
local s,id=GetID()
function s.initial_effect(c)
		--Special Summon this card by targeting a face-up card you control, then flip it facedown
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_HAND|LOCATION_GRAVE)
		e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e1:SetTarget(s.sptg)
		e1:SetOperation(s.spop)
		c:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,0))
		e2:SetCategory(CATEGORY_TOHAND)
		e2:SetType(EFFECT_TYPE_IGNITION)
		e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1,id)
		e2:SetTarget(s.tdtg)
		e2:SetOperation(s.tdop)
		c:RegisterEffect(e2)

	end

	function s.filter(c)
		return c:IsFaceup() and (
			(c:IsType(TYPE_MONSTER) and c:IsCanTurnSet()) or
			((c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable(true))
		)
	end

	function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		if chkc then return chkc:IsOnField() and s.filter(chkc) end
		if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_ONFIELD,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	end

	function s.spop(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 and tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
				if tc:IsType(TYPE_MONSTER) then
					Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
				elseif tc:IsType(TYPE_SPELL) or tc:IsType(TYPE_TRAP) then
					Duel.ChangePosition(tc,POS_FACEDOWN)
				end
			end
		end
	end

--Effect: Target 2 cards in your GY of the same type (Monster, Spell, or Trap) but with different names, shuffle them into the Deck, then add 1 card of the same type but different name from Deck to hand

function s.tdfilter(c,typ,exname,e)
	return c:IsType(typ) and c:IsAbleToDeck() and c:IsCanBeEffectTarget(e) and (not exname or c:GetCode()~=exname)
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_GRAVE,0,nil)

    -- Build a group of all cards that belong to a valid type pairing
    local validGroup=Group.CreateGroup()
    for t=TYPE_SPELL,TYPE_TRAP,TYPE_MONSTER do
        local tg=g:Filter(Card.IsType,nil,t)
        if tg:GetCount()>=2 then
            local hasPair=false
            for c1 in aux.Next(tg) do
                for c2 in aux.Next(tg) do
                    if c1~=c2 and c1:GetCode()~=c2:GetCode() then
                        hasPair=true
                        break
                    end
                end
                if hasPair then break end
            end
            if hasPair then
                validGroup:Merge(tg)
            end
        end
    end

    if chk==0 then return validGroup:GetCount()>=2 end

    -- First pick: any card from any valid type group
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local c1=validGroup:Select(tp,1,1,nil):GetFirst()

    -- Second pick: same type as first pick, different name
    local c1type
    if c1:IsType(TYPE_MONSTER) then c1type=TYPE_MONSTER
    elseif c1:IsType(TYPE_SPELL) then c1type=TYPE_SPELL
    else c1type=TYPE_TRAP end

    local tg2=validGroup:Filter(
        function(card)
            return card~=c1 and card:IsType(c1type) and card:GetCode()~=c1:GetCode()
        end, nil)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local c2=tg2:Select(tp,1,1,nil):GetFirst()

    local tg=Group.CreateGroup(); tg:AddCard(c1); tg:AddCard(c2)
    Duel.SetTargetCard(tg)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg~=2 then return end
	local typ=tg:GetFirst():GetType() & (TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP)
	if not (tg:GetFirst():IsType(typ) and tg:GetNext():IsType(typ)) then return end
	local names={} for c in aux.Next(tg) do table.insert(names,c:GetCode()) end
	if Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==2 then
		Duel.BreakEffect()
		local g=Duel.GetMatchingGroup(function(c)
			return c:IsType(typ) and c:IsAbleToHand() and not (c:GetCode()==names[1] or c:GetCode()==names[2])
		end,tp,LOCATION_DECK,0,nil)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g:Select(tp,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end

