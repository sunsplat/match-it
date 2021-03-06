<decktemplate>
    <div id="action-bar" class="row align-items-center">
        <div class="col form-inline">
            <i class="fa fa-repeat action-btn btn btn-info"  title="Arrange Randomly" onclick={ rotateRandomly }></i>

            <div class="input-group">
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" value="" id="resize-action" checked>
                    <label class="form-check-label" for="resize-action">
                        Maintain height-width ratio
                    </label>
                </div>
                <span class="fa-stack fa-lg action-btn btn btn-info" title="Resize Randomly" style="font-size: 1.2em;" onclick={resizeRandomly}>
                    <i class="fa fa-square-o fa-stack-2x" style="top: -0.5px;"></i>
                    <i class="fa fa-arrows-h fa-stack-1x" style="top: -0.5px;"></i>
                </span>
            </div>

            <i class="fa fa-random action-btn btn btn-info"  title="Arrange Randomly" onclick={ arrangeRandomly }></i>
            <i class="fa fa-copy action-btn btn btn-info"  title="Copy Pattern" onclick={ copy }></i>
            <i class="fa fa-paste action-btn btn btn-info"  title="Paste Pattern" onclick={ paste }></i>


            <label class="btn-bs-file">
                <i class="fa fa-folder-open-o action-btn btn btn-info"  title="Open Pattern file" onclick={ this.parent.arrangeRandomly }></i>
                <input id="file-input" type="file" class="filebutton" accept="application/vnd.nimn,*.nmn,*.nimn"  onchange= { readTemplateFile }/>
            </label>

            <div class="form-inline input-group">
                <input id="exportTemplateName" type="text" class="form-control" placeholder="Enter the template name " value={  exportTemplateName} style="width: 300px;">
                <i class="fa fa-save action-btn btn btn-info"  title="Save Pattern to external file" onclick={ exportTemplate }></i>
            </div>
        </div>
        <!--  <div class="col">
            <select id="templateselect" class="form-control" onchange={loadtemplate}>
                <option disabled="true">Select template</option>
                <option value="normal" selected>3-250x350-match-it</option>
                <option value="pocker" >Pocker Playing Card</option>
                <option value="domino" >Domino Card</option>
                <option value="square" >Square Card</option>
            </select>
        </div>  -->

            <!--  <button class="btn-icon"><i src="static/img/pattern.svg" title="Arrang with appropriate template" onclick={ arrangeWithTemplate }></button>  -->
        </div>
    </div>
    <!--  <div class="row warnmessage">
        <div class="col-12">This template might not be suitable for selected card size.</div>
    </div>  -->
    <script>

        selectCards(cb,...arg){
            var elArr = $(".cf-selected");

            if(elArr.length === 0){
                elArr = $(".cardframe");
            }
            elArr.each( function(i) {
                cb($(this).find(".symbol"), ...arg);
            })
        }

        arrangeRandomly(){
            this.selectCards(setRandomPos);
        }

        rotateRandomly(){
            this.selectCards(rotateSymbolsRandomly);
        }

        resizeRandomly(){
            var maintainRatio = $("#resize-action").prop("checked");
            this.selectCards(resizeSymbolsRandomly, true, maintainRatio, this.parent.frame.desiredSymbolSize);
        }

        var clipboard = null;

        copy(e){
            var selected = $(".cf-selected");
            if(e.shiftKey){
                //copy pattern weightwise
                clipboard = {};
                selected.each((i,cardEl) =>{
                    var result = this.extractPatternDataWithWeight(cardEl);
                    if( !clipboard[result.weight] ){
                        clipboard[result.weight] = [];
                    }
                    clipboard[result.weight].push( result.pattern );
                });
            }else{
                if(selected.length > 1 || selected.length === 0 ){
                    alert("Please select only 1 card.");
                }else{
                    clipboard = this.extractPatternData(selected);
                }
            }
        }

        paste(){
            var selected = $(".cf-selected");
            if(clipboard === null || selected.length === 0) return;

            if( Array.isArray(clipboard) ){//non weight
                selected.each((i,cardEl) =>{
                    this.applyPatternData( clipboard , cardEl);
                });
            }else{
                selected.each((i,cardEl) =>{
                    this.applyPatternDataWithWeight(clipboard,cardEl);
                });
            }
            //clipboard = null;
        }

        /*loadtemplate(e){

            var templateName = e.target.value + ".nimn";
            $.ajax({
                url: "./templates/"+templateName,
                type: "GET",
                dataType: "json",
                contentType: "application/vnd.nimn; charset=utf-8",
                success: data => {
                    var templateData = JSON.parse(data);
                    //this.parent.templates[templateName] = templateData;
                    //var widthDifference = ( templateData.width * 100) / Math.abs(this.parent.frame.width - templateData.width)
                    //var heightDifference = ( templateData.height * 100) / Math.abs(this.parent.frame.height - templateData.width)

                    //set margin as per height width difference

                    this.parent.applyTemplate(templateData);
                }
            });
        }*/


        extractPatternData(cardEl){
            var symbols = [];
            $(cardEl).find(".symbol").each( (si,symbol) => {
                symbols.push( this.copyStyle(symbol) );
            });
            return symbols;
        }

        applyPatternData(data,cardEl){
            $(cardEl).find(".symbol").each( (si,symbol) => {
                this.applyStyle(data[si],symbol);
            });
        }

        extractPatternDataFromMultipleCards(cardsEl){
            var cards = [];
            $(cardsEl).each( (card_i, card) => {
                cards.push( this.extractPatternData(card) );
            });
        }

        applyPatternDataOnMultipleCards(data,cardsEl){
            $(cardsEl).each( (card_i, card) => {
                this.applyPatternData(data[card_i], card);
            });
        }

        extractPatternDataWithWeight(cardEl){
            var totalWeight =0;
            var symbols = {
                "1" : [],
                "2" : []
            };

            $(cardEl).find(".symbol").each( (si,symbol) => {
                var weight = $(symbol).attr("weight");
                symbols[weight].push( this.copyStyle(symbol) );
                totalWeight += Number.parseInt(weight);
            });

            return { weight: totalWeight, pattern: symbols};
        }

/*
        1. Calculate totalWeight of a card (based on image size)
        2. Select a set *randomly* from the pattern sets for calculated weight
        3. For each symbol in selected set, apply pattern on each symbol in given card.
        */
        applyPatternDataWithWeight(data,cardEl){
            var weightSets = data[ $(cardEl).attr("totalweight") ];//there can be multiple pattern set for each weight
            if(!weightSets){//selected card has different weight
                showSnackBar("Selected card has different size of images");
                return;
            }
            var patternSet = weightSets[ randInRange(0,weightSets.length -1) ];//select one set randomly

            var weightWiseCounter = {//Each set contains symbol position info weight wise
                "1" : 0,
                "2" : 0
            }
            $(cardEl).find(".symbol").each( (si, symbol) => {
                var w = $(symbol).attr("weight");
                var index = weightWiseCounter[w];
                this.applyStyle( patternSet[ w ][ index ], symbol, true);
                weightWiseCounter[w] +=1;
            } );
        }

        applyPatternsToCards(data){
            $(".cardframe").each( (card_i, cardEl) => {
                this.applyPatternDataWithWeight(data,cardEl);//Each set contains symbol position info weight wise
            });
        }

        copyStyle(el){
            return {
                top: $(el).position().top,
                left: $(el).position().left,
                height: $(el).height(),
                width: $(el).width(),
                transform: $(el).css("transform"),
            }
        }

        applyStyle(source,target,checkWeight){
            $(target).css({
                top: source.top,
                left: source.left,
                transform: source.transform,
            });
            if(checkWeight){
                var sourceWeight = calculateWeight(source);

                var targetWeight = calculateWeight({
                    height : $(target).attr("h"),
                    width : $(target).attr("w")
                })
                if( sourceWeight !== targetWeight ){
                    rotate(target, 90);
                }
            }
            resizeSymbol($(target), source);
        }




        this.exportTemplateName = `${this.parent.frame.symbolsPerCard}-${this.parent.frame.width}x${this.parent.frame.height}-match-it`;
        readTemplateFile(f){
            var input = f.srcElement;
            if (input.files && input.files[0]) {
                var reader = new FileReader();
                reader.onload = e => {
                    //var data = JSON.parse(e.target.result);
                    var data = nimnInstance.decode(e.target.result)
                    this.applyPatternsToCards(data.cards);
                }
                reader.onloadend = e => {
                    this.update();
                    reader = null;
                }
                reader.readAsText(input.files[0]);
            }
        }

        exportTemplate(e){

            if(!$('#exportTemplateName').val()){
                showSnackBar("Oh! You've deleted template name");
                return;
            }

            var elArr = $(".cf-selected");

            if(elArr.length === 0){
                elArr = $(".cardframe");
            }

            var deck = {
                frame : this.parent.frame,
                cards: {}
            };
            $(elArr).each((fi,cardEl) => {
                var result = this.extractPatternDataWithWeight(cardEl);
                if( !deck.cards[result.weight] ){
                    deck.cards[result.weight] = [];
                }
                deck.cards[result.weight].push(result.pattern);
            })
            //TODO: convert to nimn first
            //download(JSON.stringify(deck), `${deck.frame.symbolsPerCard}-${this.frame.width}x${this.frame.height}-match-it.json` ,"application/json");
            //var data = JSON.stringify(deck);
            var data = nimnInstance.encode(deck);
            var fileName = $('#exportTemplateName').val() + ".nimn";

            download( data, fileName ,"application/vnd.nimn");
        }

        function showSnackBar(msg) {
            // Get the snackbar DIV
            $("#snackbar").text(msg);
            $("#snackbar").addClass("show");

            // After 3 seconds, remove the show class from DIV
            setTimeout(function(){ $("#snackbar").removeClass("show"); $("#snackbar").text("");}, 3000);
        }

        this.on("mount",() => {
          window.addEventListener("keypress", (press) => {
            switch(press.key) {
              case "r":
                this.selectCards(rotateSymbolsRandomly);
                break;
              case "R":
                this.resizeRandomly();
                break;
              case "a":
                this.selectCards(setRandomPos);
                break;
              case "c":
                this.copy(e);
                break;
              case "C":
                this.copy(e)
                break;
              case "v":
                this.paste();
                break;
              case "o":
                $('#file-input').trigger('click');
                break;
              case "s":
                this.exportTemplate(e);
                break;              
            }
          });
        });

    </script>
</decktemplate>
